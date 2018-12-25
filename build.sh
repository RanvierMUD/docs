set -e
git pull
(cd ../core; git pull)
npm run build-docs
mkdocs build
