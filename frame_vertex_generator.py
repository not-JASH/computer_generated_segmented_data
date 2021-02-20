import sys,bpy,bpy_extras
from os import mkdir
from os.path import join
annotation_folder = r"C:\project_data\interiors_2\renders\room_10"
bpy.context.scene.render.image_settings.file_format = 'JPEG'
start_frame = 520
total_frames = 1000
object_range = []
camera_object = []

i = 0
for obj in bpy.data.objects:
    print(obj.name,obj.type)
    if obj.type == 'CAMERA':
        camera_object.append(i)
    elif obj.type == 'MESH':
        object_range.append(i)
    i = i+1
original_out = sys.stdout
for current_frame in range(start_frame-1,total_frames):
    frame_folder = join(annotation_folder,'frame_'+str(current_frame+1))
    render_path = join(frame_folder,'frame.JPEG')
    mkdir(frame_folder) 
    scene = bpy.context.scene
    scene.frame_current = current_frame    
    scene.render.filepath = render_path
    bpy.ops.render.render(write_still=True) 
    obj = bpy.data.objects[camera_object[0]]
    for i in object_range:
        current_object = bpy.data.objects[i]
        if current_object.type == 'MESH':
            object_annotation_file = join(frame_folder,current_object.name+'_'+current_object.type+'.txt')
            with open(object_annotation_file,'w') as f:
                sys.stdout = f
                for j in range(len(current_object.data.vertices)):
                    co = current_object.matrix_world @ current_object.data.vertices[j].co
                    co_2d = bpy_extras.object_utils.world_to_camera_view(scene,obj,co)
                    print("\t",round(co_2d.x,6),round(co_2d.y,6),round(co_2d.z,6))
sys.stdout = original_out
print("finished rendering!\n")
    
    
    