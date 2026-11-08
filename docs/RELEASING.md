# Making a source release

1. Inspect the working tree, the remote branch and the existing tags. Preserve
   concurrent changes and never force-push a release over another commit.
2. Update `project(VERSION ...)` in `CMakeLists.txt`, `CHANGELOG.md` and the
   support/limitations in the README. Recheck asset licenses and notices.
3. Build and run CTest using the commands in [GETTING_STARTED.md](GETTING_STARTED.md).
   Build the standalone consumer in `examples/minimal`. Capture affected scenes
   from the real executable and inspect diagnostics. Keep existing evidence.
4. Verify the source archive can configure/build outside the original checkout.
   Include sources, tests, documentation, illustrations and license files;
   exclude Qt SDKs, compiler outputs and credentials.
5. Commit the reviewed tree and push it to the intended GitHub branch. Inspect
   the resulting Actions runs. Report each tested platform accurately; a queued
   or failed job is not verification.
6. Create a version tag at the reviewed commit. For `0.1.0`, use `v0.1.0` and
   mark the GitHub release as a **pre-release**. Attach release notes describing
   the concrete features, build entry point and remaining limitations.
7. Attach a source archive and its SHA-256 checksum. Do not call a raw build
   directory a portable binary distribution. Runtime packages require separate
   deployment work and testing on each target OS.
8. Verify the remote commit, tag and release links. Do not change repository
   visibility or publish cloud environment settings as part of a code release.

The initial release is source-only. GitHub also creates automatic source
archives from the tag; a manually attached archive provides an explicit
checksum for the reviewed source snapshot.
