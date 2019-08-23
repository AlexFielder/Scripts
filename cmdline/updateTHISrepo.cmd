@echo off
echo updating repo with latest changes
git add .
git commit -m "%DATE% %TIME%: Updating from source via batch file"
git push
