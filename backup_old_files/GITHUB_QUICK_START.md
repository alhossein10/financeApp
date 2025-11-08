# GitHub Quick Start - 5 Minutes

## Super Simple Guide to Upload Your Project

### Step 1: Create Repository on GitHub (2 min)

1. Go to https://github.com/new
2. Repository name: `finance-app`
3. Choose **Private**
4. Click **"Create repository"**
5. **Copy the URL** shown (looks like: `https://github.com/username/finance-app.git`)

### Step 2: Upload from Your Computer (3 min)

Open terminal in your project folder and run these commands:

```bash
# 1. Initialize git
git init

# 2. Add all files
git add .

# 3. Create first commit
git commit -m "Initial commit"

# 4. Connect to GitHub (replace with YOUR URL!)
git remote add origin https://github.com/YOUR_USERNAME/finance-app.git

# 5. Upload
git push -u origin main
```

If the last command fails, try:
```bash
git branch -M main
git push -u origin main
```

### Step 3: Done! 🎉

Go to your GitHub repository URL and refresh - you should see all your files!

---

## Visual Guide

```
Your Computer                    GitHub
┌──────────────┐                ┌──────────────┐
│              │                │              │
│  Your        │   git push     │  GitHub      │
│  Project  ───┼───────────────→│  Repository  │
│  Files       │                │              │
│              │                │  ✅ Backed up│
└──────────────┘                │  ✅ Shareable│
                                │  ✅ Versioned│
                                └──────────────┘
```

---

## What Gets Uploaded?

✅ **YES** - Your code, docs, configs
❌ **NO** - Build files, databases, secrets

The `.gitignore` file handles this automatically!

---

## Common Issues

### "Permission denied"
Use HTTPS URL (not SSH):
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/finance-app.git
```

### "Repository not found"
Check the URL is correct:
```bash
git remote -v
```

### "Failed to push"
Pull first:
```bash
git pull origin main --rebase
git push origin main
```

---

## After Upload

### To update later:
```bash
git add .
git commit -m "Description of changes"
git push
```

### To download on another computer:
```bash
git clone https://github.com/YOUR_USERNAME/finance-app.git
cd finance-app
flutter pub get
```

---

## Need More Help?

- Detailed guide: `GITHUB_UPLOAD_GUIDE.md`
- Checklist: `GITHUB_UPLOAD_CHECKLIST.md`

---

## That's It!

Total time: **5 minutes**

Your project is now:
- ✅ Backed up on GitHub
- ✅ Version controlled
- ✅ Ready to share
- ✅ Accessible from anywhere

🎉 Congratulations!
