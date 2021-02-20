import bpy,numpy
from math import pi
from random import uniform,randrange
from os import listdir
from os.path import join

def ss(t1,t2):
    result = tuple(numpy.subtract(t1,t2))
    return result

def aa(t1,t2):
    result = tuple(numpy.add(t1,t2))
    return result

class wall:
    def __init__(self,defining_point,height,name):
        '''
        point(1) is (0,0), defining_point is (x_component,y_component),height(z)
        '''
        self.textures = r"C:\project_data\interiors_2\wall_textures"
        self.material = random_material(self.textures,name+'_material')
        self.verts = []
        self.faces = []
                
        self.verts.append((0,0,0))
        self.verts.append((defining_point[0],defining_point[1],0))
        self.verts.append((defining_point[0],defining_point[1],height))
        self.verts.append((0,0,height))
        self.faces.append((0,1,2,3))
        self.name = name
        
class floor: 
    def __init__(self,corners,name):
        self.textures = r"C:\project_data\interiors_2\floor_textures"
        self.material = random_material(self.textures,name+'_material')
        self.verts = corners
        self.faces = []
        self.faces.append((0,1,2,3))
        self.name = name;
        
class ceiling: 
    def __init__(self,corners,name):
        self.textures = r"C:\project_data\interiors_2\wall_textures"
        self.material = random_material(self.textures,name+'_material')
        self.verts = corners
        self.faces = []
        self.faces.append((0,1,2,3))
        self.name = name;
        
class point_light:
    def __init__(self,location,name):
        self.data = bpy.data.lights.new(name=name,type='POINT')
        self.object = bpy.data.objects.new(name=name,object_data=self.data)
        bpy.context.collection.objects.link(self.object)
        self.object.location = location;
        self.data.energy = 100
        '''
        bpy.context.active_object.select_set(state=True)
        bpy.context.scene.objects.active = self.object    
        '''    
        
class cam: 
    def __init__(self,location,name):
        self.cam_1 = bpy.data.cameras.new(name)
        self.cam_1.lens = 2.1
        self.cam_1.angle = 145
        self.cam_obj = bpy.data.objects.new(name,self.cam_1)
        self.cam_obj.location = location
        r_x = 90*pi/180
        r_y = 0*pi/180
        r_z = 0*pi/180
        self.cam_obj.rotation_euler = (r_x,r_y,r_z)
        self.cam_obj.keyframe_insert('rotation_euler',index=2,frame=1)
        r_z = r_z + 360*pi/180
        self.cam_obj.rotation_euler = (r_x,r_y,r_z)
        self.cam_obj.keyframe_insert('rotation_euler',index=2,frame=360)
        bpy.context.collection.objects.link(self.cam_obj)
        
class room: 
    '''
    probably change to initialize with corners instead of h,w, startpoint
    '''
    def __init__(self,length,width,height,rotation,startpoint,name):
        self.corners = []
        self.walls = []
        self.lights = []
        for i in range(randrange(2,4)):
            self.lights.append(point_light(random_point(length,width,height,startpoint),'light_'+str(i+1)))
        self.camera = cam(random_point(length,width,0.75*height,aa(startpoint,(0,0,1))),'camera_1')
        self.name = name
        self.corners.append(startpoint)
        self.corners.append(aa(self.corners[0],(length,0,0)))
        self.corners.append(aa(self.corners[1],(0,width,0)))
        self.corners.append(aa(self.corners[2],(-length,0,0)))
        for i in range(4):
            sp = i
            ep = i+1
            if ep > 3:
                ep = 0
            self.walls.append(wall(ss(self.corners[ep],self.corners[sp]),height,self.name+'_wall_'+str(i+1)))
        self.floor = floor(self.corners,self.name+'_floor')
        self.ceiling = ceiling(aa(self.corners,(0,0,height)),self.name+'_ceiling')

def random_point(l,w,h,start):
    x = uniform(start[0],l)
    y = uniform(start[1],w)
    z = uniform(start[2],h)
    return (x,y,z)
                    
def add(feature,start_point):
    mesh = bpy.data.meshes.new(feature.name)
    object = bpy.data.objects.new(feature.name,mesh)
    object.location = start_point
    bpy.context.collection.objects.link(object)
    mesh.from_pydata(feature.verts,[],feature.faces)
    mesh.update(calc_edges=True)
    object.data.materials.append(feature.material)
    
def show_room(room):
    start_point = room.corners[0]
    for i in range(4):
        add(room.walls[i],room.corners[i])
    add(room.floor,(0,0,0))
    add(room.ceiling,(0,0,0))
    
def random_material(path_to_textures,name):
    image = listdir(path_to_textures)
    image = image[randrange(len(image))]
    image = join(path_to_textures,image)
    material = bpy.data.materials.new(name=name)
    material.use_nodes = True   
    bsdf = material.node_tree.nodes["Principled BSDF"]
    texture = material.node_tree.nodes.new('ShaderNodeTexImage') 
    texture.projection = 'BOX'
    texture.image = bpy.data.images.load(image)
    coordinates = material.node_tree.nodes.new('ShaderNodeTexCoord')
    material.node_tree.links.new(bsdf.inputs['Base Color'], texture.outputs['Color'])
    material.node_tree.links.new(coordinates.outputs['Generated'],texture.inputs['Vector'])
    return material
    
    
ll = 5
ul = 10
room1 = room(uniform(ll,ul),uniform(ll,ul),uniform(2,3),0,(0,0,0),'room_one')

show_room(room1)


"https://www.cgtrader.com/free-3d-models/furniture?author=Scopia"