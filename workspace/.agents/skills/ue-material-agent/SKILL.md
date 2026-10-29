---
name: ue-material-agent
description: Create, edit, inspect, compile, save, and validate Unreal Engine Material, Material Instance, Material Function, and Material Parameter Collection assets through Unreal Editor APIs. Use for concrete UE material asset work; do not use for renderer C++ or HLSL changes, texture image generation, runtime dynamic-material logic, or general material theory.
---

# UE Material Agent

Create real Unreal assets through the matching Unreal Editor. Never synthesize or binary-edit a `.uasset` file.

## Operating contract

- Treat inspect, explain, diagnose, and review requests as read-only for assets, source, configuration, and version-control state. Diagnostic scripts and logs under `Saved/Codex/MaterialJobs` are allowed, but never save a target package during diagnosis.
- Creating a new asset at an explicitly requested path is authorized. Editing an existing asset is authorized only when that asset is a clear target of the request.
- Do not overwrite an existing same-name asset by default. Inspect it first; report a no-op only when it already matches the requested semantics, otherwise report the conflict.
- Require explicit authorization before deleting, renaming, overwriting, or bulk-processing assets; writing under `/Engine` or plugin content; or changing source, project settings, `.uproject`, plugins, or version-control state.
- Touch and save only target packages. Do not perform a project-wide resave, redirector fix-up, cache cleanup, or broad shader rebuild.
- Never kill or restart an Editor process, discard unsaved packages, or silently persist plugin changes.
- Put generated scripts, manifests, and logs under `<Project>/Saved/Codex/MaterialJobs/<job-id>/`, never in `Content` or `Source`.
- Before changing an existing binary asset, record its package path, disk existence, dirty state, and version-control status. If a live target package is already dirty, stop and ask how to preserve the unsaved in-memory work; a disk backup is not a substitute. Otherwise, if recovery is unclear, create a job-local recoverable copy without altering source-control state.

## Resolve project and engine

1. Resolve the target `.uproject` from the request and workspace. If multiple projects are plausible, stop before mutation and ask which one to use.
2. Resolve the engine associated with that project and verify the Editor executable, project descriptor, and engine version before running a job. Resolve an `EngineAssociation` GUID through the registered Unreal builds and resolve version labels through their registered or launcher installation data. Do not infer the engine from the current working directory.
3. Read applicable repository instructions and material documentation. If the user explicitly names an available project-material skill, use it for project conventions and this skill for execution safety.
4. Inspect target assets, parents, functions, textures, and parameter collections before designing the edit.
5. If `references/project-<uproject-stem>.md` exists in this skill, read it and apply it. Do not assume a project profile exists. When the user asks to capture new project conventions, start from `references/project-profile-template.md` and keep only rules supported by the project or the user.
6. For a UE 5.8 target, read `references/ue-5.8-material-python.md`. Verify its known branch-specific behavior against the actual associated engine when that installation differs from the documented local branch.

Resolve conflicting instructions in this order: the current user request, repository instructions, the matching project profile, then this generic workflow. Safety and authorization limits still apply.

## Select execution mode

| Editor state | Mode |
| --- | --- |
| Correct project is open and a supported Python or automation bridge is available | Use that live Editor connection. |
| An Editor is open but the project does not match, or no controllable bridge is available | Do not launch a second instance or terminate the Editor; report the concrete requirement. |
| No Unreal Editor process is running | Run a narrow `UnrealEditor-Cmd.exe` Python job. |
| The request requires UI interaction, live preview, or screenshots | Use an explicitly controllable interactive Editor; commandlet mode is insufficient. |

For offline jobs, prefer this shape after resolving concrete paths:

```powershell
UnrealEditor-Cmd.exe <project.uproject> -run=PythonScript -Script=<job.py> -EnablePlugins=PythonScriptPlugin -Unattended -NoSplash -NoSound -NoP4 -stdout -FullStdOutLogOutput
```

Treat `-EnablePlugins=PythonScriptPlugin` as a transient launch option. If the required plugin or API is unavailable, explain what is missing and request permission before editing the project descriptor.

The UE console is appropriate for CVars and diagnostic commands. Build material graphs through Unreal Editor APIs, not by pretending console commands provide reliable graph authoring.

## Build a job manifest

Before mutation, form an internal manifest containing:

- project descriptor, engine version, and execution mode;
- operation and exact target package/object paths;
- asset classes and parent/reference dependencies;
- material domain, blend mode, shading model, two-sided state, and other requested settings;
- expressions, stable parameter names, types, defaults, groups, sort priorities, and connections;
- save scope and semantic validation requirements.

Translate vague visual intent into explicit material semantics. For a new general Surface material, unspecified settings may keep the matching engine's defaults when they do not conflict with the request; record those defaults in the result. Ask only when a choice materially changes the public parameter interface, asset references, rendering behavior, or requested look. A project profile may resolve those choices; otherwise do not invent project conventions.

## Create or edit assets

- Use Asset Tools and the correct Unreal factory to create `Material`, `MaterialInstanceConstant`, `MaterialFunction`, or `MaterialParameterCollection` assets.
- Before creation, check both the Asset Registry object/package path and the resolved on-disk package file for a same-name conflict.
- Use `MaterialEditingLibrary` and reflected Editor APIs to add expressions, connect expression pins and material properties, set parents and parameter values, update functions, and compile materials.
- Inspect actual function signatures and pin names for the target engine branch; do not assume an API or pin name from another UE version.
- Validate parameter setters by reading values back. Do not treat a setter's Boolean return as authoritative when the target branch is known to return an incorrect status.
- Preserve unrelated graph sections, metadata, parameter identities, and references when editing an existing asset.
- In a live Editor, use transactions when supported so an edit can be undone. In commandlet mode, keep the job narrowly scoped and fail before saving if construction or validation is incomplete.
- Do not use class-default mutation or raw package serialization as a shortcut.

## Compile, save, and validate

1. Layout expressions when it materially improves graph readability without changing semantics.
2. Recompile or update each affected material or function and wait for relevant compilation work to complete.
3. Treat returned compiler errors and matching material/compiler errors in the job log as failure; process exit code zero alone is insufficient.
4. Save only target packages and verify each save result.
5. Confirm the Asset Registry reports every expected object with the expected class.
6. Reload or independently reopen the saved asset, then re-read critical settings, nodes, connections, parents, references, parameter names, types, and defaults.
7. For a high-impact or batch job, use a second read-only process for independent verification when practical.

During read-only diagnosis, record the package's initial dirty state, do not save it, and verify that the diagnostic work did not introduce a new dirty state.

Do not claim success when an applicable compile or update step, save, registry, or reload validation is missing. Report non-applicable stages explicitly and state exactly which validation could not run.

## Failure handling

- Preserve the manifest, script, and relevant log excerpt in the job directory.
- Name the missing plugin, module, API, class, pin, reference, or permission precisely.
- Do not delete caches, intermediate data, or assets as a speculative repair.
- Do not simplify or replace the requested graph merely to make compilation pass without telling the user.

## Deliver

Report:

- assets created, modified, skipped, or left unchanged;
- `/Game/...` package and object paths;
- asset type, parent, key parameters, settings, and graph connections;
- compile, save, Asset Registry, and reload verification results;
- execution mode, job-log path, and any non-blocking warnings.
