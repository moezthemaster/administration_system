/*
 * ============================================================
 * Configuration
 * ============================================================
 */

// Composants à déployer
def components = [
    'componenta',
    'componentb',
    'componentc'
]

// Repositories Artifactory
def releaseRepo  = 'my-releases'
def snapshotRepo = 'my-snapshots'

// URL Artifactory
def artifactoryUrl = 'https://artifactory.example.com'


/*
 * ============================================================
 * Fonction principale
 * ============================================================
 */

def run() {

    /*
     * --------------------------------------------------------
     * 1. Choix de l'environnement
     * --------------------------------------------------------
     */

    def environment = input(
        message: 'Choisir l’environnement',
        parameters: [
            choice(
                name: 'ENVIRONMENT',
                choices: [
                    'dev',
                    'recette',
                    'prod'
                ],
                description: 'Environnement cible'
            )
        ]
    )


    /*
     * --------------------------------------------------------
     * 2. Choix release / snapshot pour chaque composant
     * --------------------------------------------------------
     */

    def typeParameters = []

    components.each { component ->

        typeParameters << choice(
            name: "${component}_type",
            choices: [
                'release',
                'snapshot'
            ],
            description: "Type de version pour ${component}"
        )
    }

    def typeSelection = input(
        message: 'Choisir release ou snapshot pour chaque composant',
        parameters: typeParameters
    )


    /*
     * --------------------------------------------------------
     * 3. Recherche des versions dans Artifactory
     * --------------------------------------------------------
     */

    def availableVersions = [:]

    components.each { component ->

        def selectedType = typeSelection["${component}_type"]

        def repo

        if (selectedType == 'release') {
            repo = releaseRepo
        } else {
            repo = snapshotRepo
        }

        echo "Recherche des versions de ${component} dans ${repo}"


        /*
         * AQL Artifactory
         *
         * Les artefacts sont supposés avoir le format :
         *
         * componenta_2.0.1.zip
         *
         * componenta_2.1.0.zip
         */

        def aql = """items.find({
            "repo": "${repo}",
            "name": {
                "\$match": "${component}_*.zip"
            }
        }).include("name","repo","path")"""


        /*
         * Appel Artifactory directement depuis custom.groovy.
         *
         * L'AQL est transmis à curl via stdin et aucun fichier
         * temporaire n'est créé dans le workspace.
         */

        def versionsOutput

        withCredentials([
            usernamePassword(
                credentialsId: 'artifactory-credentials',
                usernameVariable: 'ARTIFACTORY_USER',
                passwordVariable: 'ARTIFACTORY_PASSWORD'
            )
        ]) {

            versionsOutput = sh(
                script: """
                    set -e

                    printf '%s' '${aql.replace("'", "'\\\\''")}' \\
                    | curl -sS \\
                        --fail \\
                        -u "\$ARTIFACTORY_USER:\$ARTIFACTORY_PASSWORD" \\
                        -H "Content-Type: text/plain" \\
                        --data-binary @- \\
                        "${artifactoryUrl}/artifactory/api/search/aql" \\
                    | jq -r --arg component "${component}" '
                        .results[]
                        | .name
                        | capture("^" + \$component + "_(?<version>.+)\\\\.zip\\$")
                        | .version
                    ' \\
                    | sort -Vu
                """,
                returnStdout: true
            ).trim()
        }


        /*
         * Vérification
         */

        if (!versionsOutput) {
            error(
                "Aucune version trouvée pour ${component} " +
                "dans le repository ${repo}"
            )
        }


        /*
         * Transformation en liste Jenkins
         */

        def versions = versionsOutput
            .split('\\n')
            .findAll { it?.trim() }
            .collect { it.trim() }


        availableVersions[component] = versions

        echo "Versions disponibles pour ${component} : ${versions}"
    }


    /*
     * --------------------------------------------------------
     * 4. Choix d'une version pour chaque composant
     * --------------------------------------------------------
     */

    def versionParameters = []

    components.each { component ->

        versionParameters << choice(
            name: "${component}_version",
            choices: availableVersions[component],
            description: "Version de ${component}"
        )
    }


    def versionSelection = input(
        message: 'Choisir la version de chaque composant',
        parameters: versionParameters
    )


    /*
     * --------------------------------------------------------
     * 5. Construction des extra-vars
     * --------------------------------------------------------
     */

    def extraVars = [:]

    components.each { component ->

        def selectedType =
            typeSelection["${component}_type"]

        def selectedVersion =
            versionSelection["${component}_version"]


        /*
         * À adapter aux noms exacts attendus par AWX /
         * ta Shared Library.
         */

        extraVars["${component}_type"] = selectedType
        extraVars["${component}_version"] = selectedVersion
    }


    /*
     * --------------------------------------------------------
     * 6. Résumé
     * --------------------------------------------------------
     */

    echo "========================================"
    echo "Configuration sélectionnée"
    echo "========================================"
    echo "Environment : ${environment}"

    components.each { component ->

        echo "${component} : " +
             "${typeSelection["${component}_type"]} / " +
             "${versionSelection["${component}_version"]}"
    }

    echo "========================================"


    /*
     * --------------------------------------------------------
     * 7. Retour vers le Jenkinsfile
     * --------------------------------------------------------
     */

    return [
        environment: environment,
        extraVars: extraVars
    ]
}


/*
 * Nécessaire avec load('custom.groovy')
 */
return this
