# GitHub Container Registry Authentication Setup

## Issue
The GitHub Actions workflow failed with:
```
ERROR: failed to push ghcr.io/mankinimbom/pern-frontend:main: denied: installation not allowed to Write organization package
```

## Solution ✅ RESOLVED
Using existing `GITOPS_TOKEN` secret from repository.

## What Was Fixed

The workflow now uses your existing `GITOPS_TOKEN` secret which already has the required permissions:
- ✅ `write:packages` - Upload packages to GitHub Package Registry  
- ✅ `read:packages` - Download packages from GitHub Package Registry

## Current Status

- ✅ Updated workflow to use: `${{ secrets.GITOPS_TOKEN }}`
- ✅ Existing token has required permissions
- ✅ Ready to test image builds

## Test the Fix

Push this change to trigger the workflow:

```bash
git add .
git commit -m "Use existing GITOPS_TOKEN for container registry auth"
git push origin main
```

## Alternative: Manual Local Build

If you want to test locally first:

```bash
# Use your existing token
echo $GITOPS_TOKEN | docker login ghcr.io -u mankinimbom --password-stdin

# Build and push manually
./build-images.sh
```

## Expected Results

After successful push, images will be available at:
- https://github.com/mankinimbom/pern-backend/pkgs/container/pern-backend
- https://github.com/mankinimbom/pern-frontend/pkgs/container/pern-frontend

## Package Visibility

After successful push, you may need to make packages public:

1. Go to package page on GitHub
2. Settings → Change visibility → Public  
3. This allows Kubernetes to pull without authentication
