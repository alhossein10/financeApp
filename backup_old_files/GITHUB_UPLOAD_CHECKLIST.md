# GitHub Upload Checklist

## Before You Upload

### ✅ Security Check
- [ ] No API keys hardcoded in code
- [ ] No passwords in code
- [ ] PocketBase URL is `127.0.0.1` (localhost) - safe to upload
- [ ] Firebase config files are in `.gitignore`
- [ ] No `.db` files will be uploaded (in `.gitignore`)
- [ ] No keystore files (`.jks`, `.keystore`) will be uploaded
- [ ] No personal data in code

### ✅ Files Check
- [ ] `.gitignore` file exists and is updated
- [ ] `README.md` exists and describes your project
- [ ] No build artifacts (`build/`, `*.apk`, `*.ipa`)
- [ ] No large files (>100MB)

### ✅ Code Quality
- [ ] Code compiles without errors
- [ ] No TODO comments with sensitive info
- [ ] No commented-out sensitive code

---

## Upload Steps

### 1. Create GitHub Repository
- [ ] Go to https://github.com/new
- [ ] Name: `finance-app` (or your choice)
- [ ] Visibility: **Private** (recommended)
- [ ] Don't initialize with README
- [ ] Copy repository URL

### 2. Initialize Git
```bash
git init
```
- [ ] Command executed successfully

### 3. Add Files
```bash
git add .
```
- [ ] Check `git status` - files are green
- [ ] No sensitive files listed

### 4. First Commit
```bash
git commit -m "Initial commit: Finance app with user and admin versions"
```
- [ ] Commit created successfully

### 5. Connect to GitHub
```bash
git remote add origin https://github.com/YOUR_USERNAME/finance-app.git
```
- [ ] Replace `YOUR_USERNAME` with your GitHub username
- [ ] Command executed successfully

### 6. Push to GitHub
```bash
git push -u origin main
```
- [ ] Files uploaded successfully
- [ ] No errors

### 7. Verify
- [ ] Go to GitHub repository URL
- [ ] All files are visible
- [ ] README displays correctly
- [ ] No sensitive files visible

---

## After Upload

### Immediate
- [ ] Repository is accessible
- [ ] README looks good
- [ ] Files are organized

### Optional Improvements
- [ ] Add repository description
- [ ] Add topics/tags
- [ ] Add LICENSE file
- [ ] Add CONTRIBUTING.md
- [ ] Set up branch protection
- [ ] Add GitHub Actions (CI/CD)
- [ ] Add issue templates
- [ ] Add screenshots to README

---

## Files That WILL Be Uploaded

✅ Source code (`lib/`, `test/`)
✅ Configuration (`pubspec.yaml`, `analysis_options.yaml`)
✅ Documentation (`.md` files)
✅ Assets (`assets/`, `fonts/`)
✅ Platform code (`android/`, `ios/`, etc.)
✅ PocketBase backend files (Dockerfile, schema)
✅ README and guides

---

## Files That WON'T Be Uploaded

❌ Build artifacts (`build/`, `*.apk`, `*.ipa`)
❌ Dependencies (`.pub-cache/`, `.dart_tool/`)
❌ IDE files (`.idea/`, `.vscode/`)
❌ Database files (`*.db`)
❌ Firebase config (`google-services.json`)
❌ Keystore files (`*.jks`, `*.keystore`)
❌ Environment files (`.env`)
❌ Generated files (`*.g.dart`)

---

## Quick Commands

```bash
# Check what will be uploaded
git status

# See what's ignored
git status --ignored

# See all files tracked by git
git ls-files

# Remove file from git (but keep locally)
git rm --cached filename

# Undo last commit (keep changes)
git reset --soft HEAD~1

# See commit history
git log --oneline
```

---

## Troubleshooting

### Problem: Too many files
**Solution**: Check `.gitignore` is working
```bash
git status --ignored
```

### Problem: Sensitive file was added
**Solution**: Remove it before pushing
```bash
git rm --cached path/to/sensitive/file
git commit -m "Remove sensitive file"
```

### Problem: Can't push
**Solution**: Check remote URL
```bash
git remote -v
git remote set-url origin https://github.com/YOUR_USERNAME/finance-app.git
```

---

## Final Check Before Push

Run these commands:

```bash
# See what will be committed
git status

# See what's ignored (should include build/, *.db, etc.)
git status --ignored

# See all tracked files
git ls-files | grep -E "\.(db|jks|keystore|env)$"
# Should return nothing!
```

If everything looks good, push:
```bash
git push -u origin main
```

---

## Success! 🎉

Your project is now on GitHub!

**Next steps:**
1. Share the repository URL with collaborators
2. Clone on other computers to continue development
3. Set up CI/CD (optional)
4. Add more documentation

**Repository URL format:**
```
https://github.com/YOUR_USERNAME/finance-app
```

---

## Need Help?

- Full guide: `GITHUB_UPLOAD_GUIDE.md`
- Git basics: https://git-scm.com/doc
- GitHub help: https://docs.github.com
