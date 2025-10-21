# Quick Fix for Render Deployment Error

## Problem

Render is showing this error:
```
error: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```

This means Render can't find the Dockerfile in your GitHub repository.

## Solution

The Dockerfile must be in the **root** of your GitHub repository, not in a subfolder.

### Step 1: Add Dockerfile to Repository Root

Go to your `pocketbase-backend` repository and create a `Dockerfile` in the root:

**Dockerfile** (in root of repository):
```dockerfile
FROM alpine:latest

ARG PB_VERSION=0.22.0

RUN apk add --no-cache \
    unzip \
    ca-certificates

# Download and install PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && \
    chmod +x /pb/pocketbase

# Create data directory
RUN mkdir -p /pb/pb_data

EXPOSE 8080

# Start PocketBase
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb/pb_data"]
```

### Step 2: Commit and Push

```bash
cd /path/to/pocketbase-backend
git add Dockerfile
git commit -m "Add Dockerfile in root for Render"
git push origin main
```

### Step 3: Trigger Redeploy in Render

1. Go to your Render dashboard
2. Click on your service
3. Click **"Manual Deploy"** → **"Deploy latest commit"**
4. Wait for the build to complete

## Repository Structure

Your repository should look like this:

```
pocketbase-backend/
├── Dockerfile          ← Must be here!
├── README.md
└── .gitignore
```

**NOT** like this:
```
pocketbase-backend/
└── pocketbase-render/
    ├── Dockerfile      ← Wrong location!
    ├── README.md
    └── .gitignore
```

## After Fixing

Once the Dockerfile is in the root and you've pushed to GitHub:

1. Render will automatically detect the new commit
2. It will start building using the Dockerfile
3. The build should succeed this time
4. Then you can add the persistent disk as described in the guide

## Need Help?

If you're still having issues:
1. Check that the Dockerfile is in the root of your repository on GitHub
2. Make sure the file is named exactly `Dockerfile` (capital D, no extension)
3. Verify the latest commit includes the Dockerfile
4. Try manually triggering a deploy in Render
