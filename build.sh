set -e
(cd ../core; git pull)
npm run build-docs
mkdocs build
