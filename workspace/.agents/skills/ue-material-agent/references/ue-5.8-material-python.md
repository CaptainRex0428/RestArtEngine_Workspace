# UE 5.8 Material Python Notes

These notes record APIs confirmed in the local UE 5.8.1 source branch. Confirm reflected APIs against the project-associated engine when it is a different installation or revision.

## Commandlet launch

Use `-run=PythonScript -Script=<absolute-script-path>` with the project descriptor. Add `-EnablePlugins=PythonScriptPlugin` transiently when the plugin is not enabled in the project. Do not combine commandlet mode with `-ExecutePythonScript`, which is the full-Editor execution path.

Python exceptions make the commandlet return a failure code. Raise `RuntimeError` for semantic validation failures.

## Modules and creation

Load `AssetTools` and `MaterialEditor` through `unreal.load_module` before resolving their reflected types. Create assets through `AssetToolsHelpers.get_asset_tools().create_asset` and the matching factory:

- `unreal.MaterialFactoryNew`
- `unreal.MaterialInstanceConstantFactoryNew`

Use `MaterialEditingLibrary.create_material_expression`. `CreateMaterialExpressionEx` is not exposed as a Python `UFUNCTION` in the confirmed branch. Set expression fields with `set_editor_property`.

Query expression input and output names before connecting uncertain pins. Check the Boolean results of `connect_material_property` and `connect_material_expressions`.

## Compile and save

In the confirmed branch, `MaterialEditingLibrary.recompile_material` returns an array of compiler error strings. Any non-empty result is failure.

Save through the core `EditorAssetSubsystem.save_loaded_asset`, then validate existence through the subsystem and Asset Registry. This avoids depending on `EditorScriptingUtilities` being enabled.

## Material-instance return-value quirk

The confirmed UE 5.8.1 implementation of scalar, vector, texture, and static-switch `set_material_instance_*_parameter_value` functions performs the assignment but can still return `False` because its local result is not updated.

Do not interpret that return alone as failure. After each setter:

1. call the corresponding getter;
2. compare the read-back value with type-appropriate tolerance;
3. call `update_material_instance`;
4. save and reload;
5. read the value again.

Connection, compilation, save, and explicit semantic-validation failures still remain fatal.
