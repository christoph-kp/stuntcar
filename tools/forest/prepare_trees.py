"""Run with Blender: export the source LOD2 trees at two game detail levels."""
import bpy
import bmesh
import json
import hashlib
import re
import numpy as np
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
records = []

def material(source, folder):
    name = source.name
    mat = bpy.data.materials.new(name + '_game')
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value = 0.9
    shader.inputs['Base Color'].default_value = (0.12, 0.08, 0.045, 1)
    for suffix, socket in [('diff', 'Base Color'), ('rough', 'Roughness'), ('alpha', 'Alpha')]:
        path = folder / 'textures' / (name + '_' + suffix + '_1k.png')
        if not path.exists():
            continue
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images.load(str(path), check_existing=True)
        if suffix != 'diff':
            node.image.colorspace_settings.name = 'Non-Color'
        mat.node_tree.links.new(node.outputs['Color'], shader.inputs[socket])
    mat.use_backface_culling = 'twig' not in name
    return mat

for species in ['pine_tree_01', 'fir_tree_01']:
    folder = ROOT / '.tools/forest-sources' / species
    bpy.ops.wm.open_mainfile(filepath=str(folder / (species + '.blend')))
    sources = [o for o in bpy.data.objects if re.fullmatch(species + '_[abc]_LOD2', o.name)]
    materials = {}
    for original in sources:
        # The fir source stores UVMap as a vector attribute, not a UV layer.
        uv = original.data.attributes.get('UVMap')
        if uv.data_type == 'FLOAT_VECTOR':
            values = np.empty(len(uv.data) * 3, dtype=np.float32)
            uv.data.foreach_get('vector', values)
            original.data.attributes.remove(uv)
            layer = original.data.uv_layers.new(name='UVMap')
            layer.data.foreach_set('uv', values.reshape(-1, 3)[:, :2].flatten())
        variant = original.name[len(species)+1]
        for detail in ['near', 'far']:
            parts = []
            for slot, item in enumerate(original.material_slots):
                source_mat = item.material
                # Detached dead branches collapse into large cones at game detail.
                if 'dead_branches' in source_mat.name:
                    continue
                if detail == 'far' and 'bark' in source_mat.name:
                    continue
                mesh = original.data.copy()
                bm = bmesh.new()
                bm.from_mesh(mesh)
                bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != slot], context='FACES')
                bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
                bm.to_mesh(mesh)
                bm.free()
                if not mesh.polygons:
                    bpy.data.meshes.remove(mesh)
                    continue
                mesh.materials.clear()
                if source_mat.name not in materials:
                    materials[source_mat.name] = material(source_mat, folder)
                mesh.materials.append(materials[source_mat.name])
                for face in mesh.polygons:
                    face.material_index = 0
                obj = bpy.data.objects.new('part', mesh)
                bpy.context.scene.collection.objects.link(obj)
                bpy.ops.object.select_all(action='DESELECT')
                obj.select_set(True)
                bpy.context.view_layer.objects.active = obj
                triangles = sum(len(p.vertices)-2 for p in mesh.polygons)
                target = 28000 if 'twig' in source_mat.name else 1800
                if detail == 'far':
                    target = 10000 if 'twig' in source_mat.name else 450
                # Preserve thin branch tubes. Collapse turns them into broad cones.
                if triangles > target and 'bark' not in source_mat.name:
                    mod = obj.modifiers.new('Game detail', 'DECIMATE')
                    mod.ratio = target / triangles
                    bpy.ops.object.modifier_apply(modifier=mod.name)
                parts.append(obj)
            bpy.ops.object.select_all(action='DESELECT')
            for part in parts:
                part.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            bpy.ops.object.join()
            obj = parts[0]
            obj.name = species + '_' + variant + '_' + detail
            low = min(v.co.z for v in obj.data.vertices)
            for vertex in obj.data.vertices:
                vertex.co.z -= low
            output = ROOT / 'assets/forest/trees' / (obj.name + '.glb')
            output.parent.mkdir(parents=True, exist_ok=True)
            bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', use_selection=True,
                                      export_yup=True, export_animations=False, export_cameras=False,
                                      export_lights=False, export_image_format='AUTO')
            triangles = sum(len(p.vertices)-2 for p in obj.data.polygons)
            records.append({'path': str(output.relative_to(ROOT)), 'source': species,
                            'source_detail': 'LOD2', 'detail': detail, 'triangles': triangles,
                            'bytes': output.stat().st_size,
                            'sha256': hashlib.sha256(output.read_bytes()).hexdigest()})
            print('EXPORTED', obj.name, triangles, flush=True)
            bpy.data.objects.remove(obj, do_unlink=True)

(ROOT / 'assets/forest/trees/variants.json').write_text(json.dumps(records, indent=2) + '\n')
