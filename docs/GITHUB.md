# Push code and connect to GitHub

Use these steps to connect this folder to your GitHub repo and push.

1. **Open a terminal in the project root**  
   `c:\Users\wildk\OneDrive\Important files\Project Source\App Development\Drift`

2. **Initialize Git (if not already)**  
   - Run: `git status`  
   - If you see "not a git repository", run: `git init`

3. **Add your GitHub repo as remote**  
   Replace `YOUR_USERNAME` and `YOUR_REPO` with your GitHub username and repo name:

   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   ```

   If you use SSH:

   ```bash
   git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
   ```

   If `origin` already exists with the wrong URL:

   ```bash
   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   ```

4. **Stage, commit, and push**  
   ```bash
   git add .
   git commit -m "Initial Drift app: iOS, Watch, backend, Garmin/Health pipeline"
   git branch -M main
   git push -u origin main
   ```

   If the repo already has commits (e.g. a README created on GitHub), pull first:

   ```bash
   git pull origin main --rebase
   git push -u origin main
   ```

5. **Secrets**  
   The repo `.gitignore` already excludes `backend/.venv/`, `backend/.env`, `GoogleService-Info.plist`, and other secrets. Do not remove these entries.

After this, your code is on GitHub. You can connect the same repo to Render for deploys when you want a public backend URL.
