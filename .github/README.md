# iocage-test

```bash
### Create orphan branch for the fork

- `git checkout --orphan foo`

```bash
git checkout --orphan run-cl
git rm -rf *
## This branch is now an empty repository
git add README.md
git commit -m "initial commit message"
git push origin stay-away
```