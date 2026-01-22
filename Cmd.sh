awk '/^---$/ && !in_comment {p=0} /DEV1/ && !p && !in_comment {p=1} p && !in_comment {print} /^[[:space:]]*#/ {next} {sub(/[[:space:]]*#.*$/, "")} !/^[[:space:]]*$/ && !/^[[:space:]]*#/ {in_comment=0} /^[[:space:]]*#/ {in_comment=1}' fichier.yaml

https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publishers/ms-vscode-remote/vsextensions/remote-ssh/0.121.2025072915/vspackage

https://ms-vscode.gallery.vsassets.io/_apis/public/gallery/publishers/ms-vscode/vsextensions/remote-explorer/0.6.2025081809/vspackage
