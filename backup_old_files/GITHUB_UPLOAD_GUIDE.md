# GitHub Upload Guide

## Step-by-Step Guide to Upload Your Project to GitHub

### Prerequisites

1. **Git installed** on your computer
   - Windows: Download from https://git-scm.com/download/win
   - Check if installed: `git --version`

2. **GitHub account** created
   - Sign up at https://github.com

### Step 1: Create a New Repository on GitHub (2 minutes)

1. Go to https://github.com
2. Click the **"+"** button (top right) → **"New repository"**
3. Fill in:
   - **Repository name**: `finance-app` (or your preferred name)
   - **Description**: "Flutter finance management app with user and admin versions"
   - **Visibility**: Choose **Private** (recommended) or Public
   - **DO NOT** check "Initialize with README" (we already have one)
   - **DO NOT** add .gitignore (we already have one)
4. Click **"Create repository"**
5. **Copy the repository URL** (looks like: `https://github.com/YOUR_USERNAME/finance-app.git`)

### Step 2: Initialize Git in Your Project (1 minute)

Open terminal/command prompt in your project folder and run:

```bash
# Initialize git repository
git init

# Check status (see what files will be added)
git status
```

### Step 3: Add Files to Git (1 minute)

```bash
# Add all files (respects .gitignore)
git add .

# Check what was added
git status
```

You should see files in green (ready to commit).

### Step 4: Create First Commit (1 minute)

```bash
# Commit with a message
git commit -m "Initial commit: Finance app with user and admin versions"
```

### Step 5: Connect to GitHub (1 minute)

```bash
# Add GitHub as remote (replace with YOUR repository URL)
git remote add origin https://github.com/YOUR_USERNAME/finance-app.git

# Verify remote was added
git remote -v
```

### Step 6: Push to GitHub (1 minute)

```bash
# Push to GitHub (main branch)
git push -u origin main
```

If you get an error about "master" vs "main", try:
```bash
git branch -M main
git push -u origin main
```

### Step 7: Verify Upload (1 minute)

1. Go to your GitHub repository URL
2. Refresh the page
3. You should see all your files! 🎉

---

## What Gets Uploaded?

### ✅ Included (Will be uploaded):
- All source code (`lib/`, `test/`)
- Configuration files (`pubspec.yaml`, `analysis_options.yaml`)
- Documentation (all `.md` files)
- Assets (`assets/`, `fonts/`)
- Platform-specific code (`android/`, `ios/`, `windows/`, etc.)
- PocketBase backend files (`pocketbase-backend-files/`)

### ❌ Excluded (Won't be uploaded):
- Build artifacts (`build/`, `*.apk`, `*.ipa`)
- Dependencies (`node_modules/`, `.pub-cache/`)
- IDE files (`.idea/`, `.vscode/`)
- Sensitive files (`google-services.json`, API keys)
- Generated files (`.dart_tool/`, `.flutter-plugins`)
- Local databases (`.db` files)

---

## Important: Protect Sensitive Information

### Before Uploading, Check These Files:

1. **PocketBase URL** (`lib/core/config/pocketbase_config.dart`)
   - ✅ Currently set to `127.0.0.1` (safe to upload)
   - ⚠️ If you change to production URL, consider using environment variables

2. **Firebase Config** (if you added it)
   - ✅ Already in `.gitignore`
   - Files like `google-services.json` won't be uploaded

3. **API Keys** (if any)
   - Make sure they're not hardcoded
   - Use environment variables or config files in `.gitignore`

---

## Common Issues & Solutions

### Issue 1: "Permission denied (publickey)"

**Solution**: Use HTTPS instead of SSH, or set up SSH keys

```bash
# Use HTTPS URL (easier)
git remote set-url origin https://github.com/YOUR_USERNAME/finance-app.git
```

### Issue 2: "Repository not found"

**Solution**: Check the URL is correct

```bash
# Check current remote
git remote -v

# Update if wrong
git remote set-url origin https://github.com/YOUR_USERNAME/finance-app.git
```

### Issue 3: "Failed to push some refs"

**Solution**: Pull first, then push

```bash
git pull origin main --rebase
git push origin main
```

### Issue 4: Too many files / Large files

**Solution**: Check .gitignore is working

```bash
# See what's being tracked
git ls-files

# If you see build files, they shouldn't be there
# Remove them from git:
git rm -r --cached build/
git commit -m "Remove build files"
```

---

## After Upload: Clone on Another Computer

To download your project on another computer:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/finance-app.git

# Navigate into folder
cd finance-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Updating Your Repository Later

When you make changes:

```bash
# Check what changed
git status

# Add changes
git add .

# Commit with message
git commit -m "Description of what you changed"

# Push to GitHub
git push
```

---

## Creating a Good README for GitHub

Your project already has a README.md, but you might want to add:

1. **Screenshots** of your app
2. **Installation instructions**
3. **How to build** user and admin versions
4. **PocketBase setup** instructions
5. **License** information

---

## Branch Strategy (Optional)

For better organization:

```bash
# Create development branch
git checkout -b development

# Make changes, commit, push
git push -u origin development

# When ready, merge to main
git checkout main
git merge development
git push
```

---

## .gitignore is Already Configured

Your project already has a good `.gitignore` that excludes:
- Build files
- IDE files
- Firebase config files
- Generated files
- Dependencies

---

## Quick Command Reference

```bash
# Check status
git status

# Add all files
git add .

# Commit
git commit -m "Your message"

# Push
git push

# Pull latest changes
git pull

# See commit history
git log

# Create new branch
git checkout -b branch-name

# Switch branch
git checkout branch-name

# See all branches
git branch -a
```

---

## Security Checklist Before Upload

- [ ] No API keys in code
- [ ] No passwords in code
- [ ] No personal data in code
- [ ] Firebase config files in .gitignore
- [ ] PocketBase URL is localhost (or use env variables)
- [ ] No `.db` files included
- [ ] No build artifacts included

---

## Making Repository Private

If you uploaded as public and want to change:

1. Go to repository on GitHub
2. Click **Settings**
3. Scroll to **Danger Zone**
4. Click **Change visibility**
5. Select **Private**

---

## Adding Collaborators

To let others contribute:

1. Go to repository on GitHub
2. Click **Settings**
3. Click **Collaborators**
4. Click **Add people**
5. Enter their GitHub username

---

## Next Steps After Upload

1. ✅ Repository is on GitHub
2. Add a nice README with screenshots
3. Add GitHub Actions for CI/CD (optional)
4. Set up branch protection rules (optional)
5. Add issues/project board for tracking (optional)

---

## Need Help?

- GitHub Docs: https://docs.github.com
- Git Docs: https://git-scm.com/doc
- GitHub Desktop (GUI): https://desktop.github.com

---

## Summary

**Total time**: ~7 minutes

**Commands to run**:
```bash
git init
git add .
git commit -m "Initial commit: Finance app with user and admin versions"
git remote add origin https://github.com/YOUR_USERNAME/finance-app.git
git push -u origin main
```

That's it! Your project is now on GitHub! 🎉
