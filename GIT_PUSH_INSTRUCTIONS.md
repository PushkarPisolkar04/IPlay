# Git Push Instructions for IPlay Repository

## Step 1: Link to Your Existing Repository

Replace `<your-repo-url>` with your actual GitHub repository URL:

```bash
git remote add origin <your-repo-url>
```

Example:
```bash
git remote add origin https://github.com/yourusername/iplay.git
```

## Step 2: Verify Remote is Added

```bash
git remote -v
```

You should see:
```
origin  https://github.com/yourusername/iplay.git (fetch)
origin  https://github.com/yourusername/iplay.git (push)
```

## Step 3: Push to Repository (Force Push to Replace Old Content)

⚠️ **WARNING**: This will replace all content in your existing repository!

If you want to completely replace the old non-working code:

```bash
git push -u origin master --force
```

Or if your default branch is `main`:

```bash
git branch -M main
git push -u origin main --force
```

## Alternative: Keep Old History (Merge Approach)

If you want to preserve the old repository history:

1. First pull the existing content:
   ```bash
   git pull origin master --allow-unrelated-histories
   ```

2. Resolve any conflicts (if any)

3. Push normally:
   ```bash
   git push -u origin master
   ```

## Step 4: Verify on GitHub

Visit your repository on GitHub and verify that:
- ✅ All files are present
- ✅ Sensitive files are NOT visible:
  - `android/app/google-services.json` ❌ Should NOT be there
  - `lib/firebase_options.dart` ❌ Should NOT be there
  - `android/local.properties` ❌ Should NOT be there
  - `functions/node_modules/` ❌ Should NOT be there
- ✅ README.md displays correctly
- ✅ SETUP_INSTRUCTIONS.md is visible

## Important Security Notes

🔒 **Protected Files (not in repository):**
- `android/app/google-services.json` - Firebase Android config
- `lib/firebase_options.dart` - Firebase Dart config
- `android/local.properties` - Local SDK paths
- `functions/node_modules/` - Node.js dependencies
- `.env` files - Environment variables

These files are excluded via `.gitignore` and should NEVER be committed.

## Next Steps After Pushing

1. **Add collaborators** (if needed) in GitHub Settings
2. **Set up branch protection** for main/master branch
3. **Create a `.github/workflows/` folder** for CI/CD (optional)
4. **Share SETUP_INSTRUCTIONS.md** with team members

## Team Members Setup

When team members clone the repository, they must:
1. Clone the repo
2. Follow `SETUP_INSTRUCTIONS.md` to configure Firebase
3. Add their own `google-services.json` and `firebase_options.dart`
4. Run `flutter pub get`
5. Run `cd functions && npm install` (for Cloud Functions)

## Quick Commands Reference

```bash
# Check what will be pushed
git log --oneline

# Check commit size
git count-objects -vH

# View ignored files
git status --ignored

# Check which files are tracked
git ls-files
```

## Troubleshooting

### "Repository not found"
- Verify repository URL is correct
- Ensure you have access permissions

### "Updates were rejected"
- Use `--force` flag if you want to replace old content
- Or use `git pull --allow-unrelated-histories` first

### "Permission denied"
- Check your GitHub authentication (SSH key or Personal Access Token)
- For HTTPS: May need to use Personal Access Token instead of password

---

**Ready to push?** Run the commands in Step 1-3 above!

