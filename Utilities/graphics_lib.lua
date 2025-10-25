---@diagnostic disable: duplicate-set-field, inject-field, missing-return, unused-local, redundant-parameter, duplicate-doc-field
--[[ common/ac_scene.lua ]]

---Mesh vertex.
---@param pos vec3 
---@param normal vec3 
---@param uv vec2 
---@return ac.MeshVertex
function ac.MeshVertex(pos, normal, uv) end

---Mesh vertex.
---@class ac.MeshVertex
---@field pos vec3
---@field normal vec3
---@field uv vec2
local _ac_MeshVertex = nil

---Creates new mesh vertex.
---@param pos vec3
---@param normal vec3
---@param uv vec2
---@return ac.MeshVertex
function ac.MeshVertex.new(pos, normal, uv) end

---Buffer with mesh vertices. Contains `ac.MeshVertex` items.
---@param size nil|integer|ac.MeshVertex[] "Initial size or initializing values."
---@return ac.VertexBuffer
function ac.VertexBuffer(size) end

---Buffer with mesh vertices. Contains `ac.MeshVertex` items.
---@class ac.VertexBuffer : ac.GenericList
local _ac_VertexBuffer = nil

---@param index integer @1-based index.
---@return ac.MeshVertex
function _ac_VertexBuffer:get(index) end

---@param index integer @1-based index.
---@param vertex ac.MeshVertex
function _ac_VertexBuffer:set(index, vertex) end

---Buffer with mesh indieces. Contains `integer` items (limited by 16 bits for AC to handle).
---@param size nil|integer|integer[] "Initial size or initializing values."
---@return ac.IndicesBuffer
function ac.IndicesBuffer(size) end

---Buffer with mesh indieces. Contains `integer` items (limited by 16 bits for AC to handle).
---@class ac.IndicesBuffer : ac.GenericList
local _ac_IndicesBuffer = nil

---Collect list of textures in KN5 file.
---@param kn5Filename string
---@param filter string? @Texture names filter. Default value: `'?'`.
---@return string[]? @Returns `nil` if there is no such file, no access to it or the file is damaged.
function ac.collectKN5TextureNames(kn5Filename, filter) end

---Collect list of material properties in KN5 file in a form of shader replacements config.
---@param kn5Filename string
---@param filter string? @Material names filter. Default value: `'?'`.
---@return string[]? @Returns `nil` if there is no such file, no access to it or the file is damaged.
function ac.collectKN5MaterialProperties(kn5Filename, filter) end

---Reference to one or several objects in scene. Works similar to those jQuery things which would refer to one or
---several of webpage elements. Use methods like `ac.findNodes()` to get one. Once you have a reference to some nodes,
---you can load additional KN5s, create new nodes and such in it.
---Note: it might be beneficial in general to prefer methods like `ac.findNodes()` and `ac.findMeshes()` over `ac.findAny()`.
---Should be fewer surprises this way.
---@class ac.SceneReference
local _ac_SceneReference = nil

---Dispose any resources associated with this `ac.SceneReference` and empty it out. Use it if you need to remove a previously
---created node or a loaded KN5.
function _ac_SceneReference:dispose() end

---Set debug outline for meshes in the reference. Outline remains active until explicitly disabled or until reference is released.
---Note: each outlined group adds a render target switch and additional draw calls, so avoid adding it to more than, let’s say,
---ten groups at once (each group can have multiple meshes in it). 
---@param color rgbm? @Outline color. Use `nil` or transparent color to disable outline.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setOutline(color) end

---Set material property. Be careful to match the type (you need the same amount of numeric values). If you’re using boolean,-
---resulting value will be either 1 or 0.
---@param property string|"'ksEmissive'"
---@param value number|vec2|vec3|rgb|vec4|rgbm|boolean
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setMaterialProperty(property, value) end

---Set material texture. Three possible uses:
---
---1. Pass color to create a new solid color texture:
---  ```
---  meshes:setMaterialTexture('txDiffuse', rgbm(1, 0, 0, 1)) -- for red color
---  ```
---2. Pass filename to load a new texture. Be careful, it would load texture syncronously unless it
---  was loaded before:
---  ```
---  meshes:setMaterialTexture('txDiffuse', 'filename.dds')
---  ```
---  Since 0.2.2 nothing will happen if the texture is missing (previously it’ll use black transparent texture).
---3. Pass a table with parameters to draw a texture in a style of scriptable displays. Be careful as to
---  not call it too often, make sure to limit refresh rate unless you really need a quick update. If you’re
---  working on a track script, might also be useful to check if camera is close enough with something like
---  ac.getSim().cameraPosition:closerToThan(display coordinates, some distance)
---  ```
---  meshes:setMaterialTexture('txDiffuse', {
---    textureSize = vec2(1024, 1024), -- although optional, I recommend to set it: skin could replace texture by one with different resolution
---    background = rgbm(1, 0, 0, 1),  -- set to `nil` (or remove) to reuse original texture as background, set to `false` to skip background preparation completely
---    region = {                      -- if not set, whole texture will be repainted
---        from = vec2(200, 300),
---        size = vec2(400, 400)
---    },
---    callback = function (dt)
---      display.rect{ pos = …, size = …, … }
---    end
---  })
---  ```
---@param texture string|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Name of a texture slot.
---@param value {callback: fun(dt: number), textureSize: vec2, region: {from: vec2, size: vec2}, background: rgbm|boolean|nil}|`{callback = function (dt)  end, textureSize = vec2(512, 512), region = {from = vec2(0, 0), size = vec2(512, 512)}}`
---@overload fun(texture: string, value: string)
---@overload fun(texture: string, value: rgbm)
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setMaterialTexture(texture, value) end

---Ensures all materials are unique, allowing to alter their textures and material properties without affecting the rest of the scene. Only
---ensures uniqueness relative to the rest of the scene. For example, if it refers to two meshes using the same material, they’ll continue
---to share material, but it would be their own material, separate from the scene.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:ensureUniqueMaterials() end

---Stores current transformation to be restored when `ac.SceneReference` is disposed (for example, when script reloads). Might be a good
---idea to use it first on any nodes you’re going to move, so all of them would get back when script is reloaded (assuming their original 
---transformation is important, like it is with needles, for example).
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:storeCurrentTransformation() end

---CSP keeps track of previous world position of each node to do its motion blur. This call would clear that value, so teleported, for
---example, objects wouldn’t have motion blur artifacts for a frame.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:clearMotion() end

---Number of elements in this reference. Alternatively, you can use `#` operator.
---@return integer
function _ac_SceneReference:size() end

---If reference is empty or not.
---@return boolean
function _ac_SceneReference:empty() end

---Find any children that match filter and return a new reference to them.
---@param filter string @Node/mesh filter.
---@return ac.SceneReference @Reference to found scene elements.
function _ac_SceneReference:findAny(filter) end

---Find any child nodes that match filter and return a new reference to them.
---@param filter string @Node filter.
---@return ac.SceneReference @Reference to found nodes.
function _ac_SceneReference:findNodes(filter) end

---Find any child meshes that match filter and return a new reference to them.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found meshes.
function _ac_SceneReference:findMeshes(filter) end

---Find any child skinned meshes that match filter and return a new reference to them.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:findSkinnedMeshes(filter) end

---Find any child objects of a certain class that match filter and return a new reference to them.
---@param objectClass ac.ObjectClass @Objects class.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:findByClass(objectClass, filter) end

---Filters current reference and returns new one with objects that match filter only.
---@param filter string @Node/mesh filter.
---@return ac.SceneReference @Reference to found scene elements.
function _ac_SceneReference:filterAny(filter) end

---Filters current reference and returns new one with nodes that match filter only.
---@param filter string @Node filter.
---@return ac.SceneReference @Reference to found nodes.
function _ac_SceneReference:filterNodes(filter) end

---Filters current reference and returns new one with meshes that match filter only.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found meshes.
function _ac_SceneReference:filterMeshes(filter) end

---Filters current reference and returns new one with skinned meshes that match filter only.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:filterSkinnedMeshes(filter) end

---Filters current reference and returns new one with objects of a certain class that match filter only.
---@param objectClass ac.ObjectClass @Objects class.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:filterByClass(objectClass, filter) end

---Create a new node with a given name and attach it as a child.
---@param name string
---@param keepAlive boolean|`true`|`false` @Set to `true` to create a long-lasting node which wouldn’t be removed when script is reloaded.
---@return ac.SceneReference @Newly created node or `nil` if failed
function _ac_SceneReference:createNode(name, keepAlive) end

---Create a new mesh with a given name and attach it as a child. Steals passed vertices and indices to avoid reallocating
---memory, so make sure to use `vertices:clone()` when passing if you want to keep the original data. 
---@param name string
---@param materialName string?
---@param vertices ac.VertexBuffer
---@param indices ac.IndicesBuffer
---@param keepAlive boolean|`true`|`false` @Set to `true` to create a long-lasting node which wouldn’t be removed when script is reloaded.
---@param moveData boolean? @Set to `true` to move vertices and indices data thus saving on reallocating memory. You can use `vertices:clone()` for one of them to retain original array. Default value: `false`.
---@return ac.SceneReference @Newly created mesh or `nil` if failed
function _ac_SceneReference:createMesh(name, materialName, vertices, indices, keepAlive, moveData) end

---Replace mesh vertices dynamically. New number of vertices should match existing one, indices work the same. Can be used for dynamic
---mesh alteration (for example, deformation). Calling it each frame with highly detailed mesh might still affect performance negatively though.
---@param vertices ac.VertexBuffer
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:alterVertices(vertices) end

---Get vertices of a first mesh in selection. Makes a copy into an `ac.VertexBuffer`, so it might be expensive to call each frame, but it can be called
---once for those vertices to later be used with `:alterVertices()` method.
---@return ac.VertexBuffer? @Returns `nil` if there are no suitable meshes in selection.
function _ac_SceneReference:getVertices() end

---Create a new bounding sphere node with a given name and attach it as a child. Using those might help with performance: children
---would skip bounding frustum test, and whole node would not get traversed during rendering if it’s not in frustum.
---
---Note: for it to work properly, it’s better to attach it to AC cars node, as that one does expect those bounding sphere nodes
---to be inside of it. You can find it with `ac.findNodes('carsRoot:yes')`.
---@param name string
---@param radius number @Radius in meters.
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:createBoundingSphereNode(name, radius) end

---Load KN5 model and attach it as a child. To use remote models, first load them with `web.loadRemoteModel()`.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:loadKN5(filename) end

---Load KN5 LOD model and attach it as a child. Parameter `mainFilename` should refer to the main KN5 with all the textures.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance. Main KN5 would be
---loaded as well, but not shown, and instead kept in a pool.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param mainFilename string @Main KN5 filename relative to script folder or AC root folder.
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:loadKN5LOD(filename, mainFilename) end

---Load KN5 model and attach it as a child asyncronously. To use remote models, first load them with `web.loadRemoteModel()`.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param callback fun(err: string, loaded: ac.SceneReference?) @Callback called once model is loaded.
function _ac_SceneReference:loadKN5Async(filename, callback) end

---Load KN5 model and attach it as a child asyncronously. Parameter `mainFilename` should refer to the main KN5 with all the textures.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance. Main KN5 would be
---loaded as well, but not shown, and instead kept in a pool.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param mainFilename string @Main KN5 filename relative to script folder or AC root folder.
---@param callback fun(err: string, loaded: ac.SceneReference?) @Callback called once model is loaded.
function _ac_SceneReference:loadKN5LODAsync(filename, mainFilename, callback) end

---Loads animation from a file (on first call only), sets animation position. To use remote animations, first load them with `web.loadRemoteAnimation()`.
---@param filename string @Animation filename (”…ksanim”). If set to `nil`, no animation will be applied.
---@param position number? @Animation position from 0 to 1. Default value: 0.
---@param force boolean? @If not set to `true`, animation will be applied only if position is different from position used previously. Default value: `false`.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setAnimation(filename, position, force) end

---@param visible boolean|`true`|`false`
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setVisible(visible) end

---@param shadows boolean|`true`|`false`
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setShadows(shadows) end

---@param exclude boolean|`true`|`false`
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:excludeFromCubemap(exclude) end

---@param exclude boolean|`true`|`false`
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:excludeFromSecondary(exclude) end

---@param transparent boolean|`true`|`false`
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setTransparent(transparent) end

---@param mode render.BlendMode
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setBlendMode(mode) end

---@param mode render.CullMode
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setCullMode(mode) end

---@param mode render.DepthMode
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setDepthMode(mode) end

---Sets attribute associated with current meshes or nodes. Attributes are stored as strings, but you can access them as numbers with `:getAttibute()` by
---passing number as `defaultValue`. To find meshes with a certain attribute, use “hasAttribute:name” search query.
---@param key string
---@param value number|string|nil @Pass `nil` to remove an attribute.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setAttribute(key, value) end

---Gets an attribute value.
---@param key string
---@param defaultValue number|string|nil @If `nil` is passed, returns string (or `nil` if attribute is not set).
---@return string|number|nil @Type is determined based on type of `defaultValue`.
function _ac_SceneReference:getAttribute(key, defaultValue) end

---Reference:
---- Reduced TAA: 1;
---- Extra TAA: 0.5.
---@param value number
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setMotionStencil(value) end

---Sets position of a node (or nodes).
---
---Note: only nodes can move. If you need to move meshes, find their parent node and move it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param pos vec3
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setPosition(pos) end

---Sets orientation of a node (or nodes). If vector `up` is not provided, facing up vector will be used.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param look vec3
---@param up vec3|nil
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setOrientation(look, up) end

---Replaces orientation of a node (or nodes) with rotational matrix. If you want to just rotate node from its current orientation, use `:rotate()`.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param axis vec3
---@param angleRad number
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setRotation(axis, angleRad) end

---Rotates node (or nodes) relative to its current orientation. If you want to completely replace its orientation by rotating matrix, use `:setRotation()`.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param axis vec3
---@param angleRad number
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:rotate(axis, angleRad) end

---Returns position of a first node relative to its parent.
---@return vec3
function _ac_SceneReference:getPosition() end

---Returns direction a first node is looking towards relative to its parent.
---@return vec3
function _ac_SceneReference:getLook() end

---Returns direction upwards of a first node relative to its parent.
---@return vec3
function _ac_SceneReference:getUp() end

---Returns number of children of all nodes in current scene reference.
---@return integer
function _ac_SceneReference:getChildrenCount() end

---Returns reference to transformation matrix of the first node relative to its parent. If you need to move
---something often, accessing its matrix directly might be the best way. Be careful though, if there
---are no nodes in the list, it would return `nil`.
---@return mat4x4 @Reference to transformation matrix of the first node, or nil. Use `mat4x4:set()` to update its value, or access its rows directly.
function _ac_SceneReference:getTransformationRaw() end

---Returns world transformation matrix of the first node. Do not use it to move node in world space (if you need
---to move in world space, either use `ref:getTransformationRaw():set(worldSpaceTransform:mul(ref:getParent():getWorldTransformationRaw():inverse()))` or
---simply move your node to a node without transformation, like root of dynamic objects). Be careful though, if there
---are no nodes in the list, it would return `nil`.
---@return mat4x4 @Reference to transformation matrix of the first node, or nil. Use `mat4x4:set()` to update its value, or access its rows directly.
function _ac_SceneReference:getWorldTransformationRaw() end

---Returns AABB (minimum and maximum coordinates in vector) of static meshes in current selection. Only regular static meshes
---are taken into account (meshes created when KN5 is exported in track mode).
---@return vec3 @Minimum coordinate.
---@return vec3 @Maximum coordinate.
---@return integer @Number of static meshes in selection.
function _ac_SceneReference:getStaticAABB() end

---Returns AABB (minimum and maximum coordinates in vector) of meshes in current selection in local mesh coordinates. Recalculates
---AABB live, might take some time with high-poly meshes.
---@return vec3 @Minimum coordinate.
---@return vec3 @Maximum coordinate.
---@return integer @Number of static meshes in selection.
function _ac_SceneReference:getLocalAABB() end

---Returns a new scene reference with a child in certain index (assuming current scene reference points to node). If current reference
---contains several nodes, children from all of them at given index will be collected.
---@param index integer? @1-based index of a child. Default value: 1.
---@return ac.SceneReference
function _ac_SceneReference:getChild(index) end

---Returns a new scene reference with first-class children (not children of children) of all nodes in current reference.
---@return ac.SceneReference
function _ac_SceneReference:getChildren() end

---Returns a new scene reference with a parent of an object in current scene reference. If current reference
---contains several objects, parents of all of them will be collected.
---@return ac.SceneReference
function _ac_SceneReference:getParent() end

---Adds nodes and meshes from another scene reference to current scene reference.
---@param sceneRef ac.SceneReference @Scene reference to append.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:append(sceneRef) end

---Removes nodes and meshes from another scene reference from current scene reference.
---@param sceneRef ac.SceneReference @Scene reference to remove.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:subtract(sceneRef) end

---Returns `true` if there is a node from `childSceneRef` somewhere in this node.
---@param childSceneRef ac.SceneReference @Scene reference to remove.
---@return boolean
function _ac_SceneReference:contains(childSceneRef) end

---Clears current scene reference.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:clear() end

---Casts a ray prepared by something like `render.createRay(pos, dir, length)` or `render.createMouseRay()`.
---
---If you need to access a mesh that was hit, set second argument to true:
---```
---local hitDistance, hitMesh = mesh:raycast(render.createRay(pos, dir), true)
---if hitDistance ~= -1 then
---  print(hitMesh:name())
---end
---```
---Alternatively, reuse your own scene reference for better performance if you need to cast
---a lot of rays:
---```
---local hitMesh = ac.emptySceneReference()
---local hitDistance = mesh:raycast(render.createRay(pos, dir), hitMesh)
---if hitDistance ~= -1 then
---  print(hitMesh:name())
---end
---```
---@param ray ray
---@param outSceneRef ac.SceneReference|boolean|nil
---@param outPosRef vec3|nil @Local position (not the world one).
---@param outNormalRef vec3|nil @Local normal.
---@param outUVRef vec2|nil @Texture coordinate.
---@return number @Distance to hit, or -1 if there was no hit.
---@return ac.SceneReference|nil @Reference to a mesh that was hit (same as `outSceneRef`, doubled here for convenience).
function _ac_SceneReference:raycast(ray, outSceneRef, outPosRef, outNormalRef, outUVRef) end

---Get name of an element.
---@param index integer|nil @1-based index of an element to get a name of. Default value: 1.
---@return string @Node or mesh name.
function _ac_SceneReference:name(index) end

---Get class of an element.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return ac.ObjectClass @Number for class of an object.
function _ac_SceneReference:class(index) end

---Get material name of an element.
---@param index integer|nil @1-based index of an element to get a material name of. Default value: 1.
---@return string @Material name.
function _ac_SceneReference:materialName(index) end

---Get shader name of an element.
---@param index integer|nil @1-based index of an element to get a shader name of. Default value: 1.
---@return string @Shader name.
function _ac_SceneReference:shaderName(index) end

---Get number of texture slots of an element.
---@param index integer|nil @1-based index of an element to get number of texture slots of. Default value: 1.
---@return integer @Number of texture slots.
function _ac_SceneReference:getTextureSlotsCount(index) end

---Get number of material properties of an element.
---@param index integer|nil @1-based index of an element to get number of material properties of. Default value: 1.
---@return integer @Number of material properties.
function _ac_SceneReference:getMaterialPropertiesCount(index) end

---Get name of a certain texture slot of an element.
---@param index integer|nil @1-based index of an element to get a name of a certain texture slot of. Default value: 1.
---@param slotIndex integer|nil @1-based index of a texture slot. Default value: 1.
---@return string|nil @Texture slot name (like “txDiffuse” or “txNormal”) or `nil` if there is no such element or property.
function _ac_SceneReference:getTextureSlotName(index, slotIndex) end

---Get name of a certain material property of an element.
---@param index integer|nil @1-based index of an element to get a name of a certain material property of. Default value: 1.
---@param slotIndex integer|nil @1-based index of a material property. Default value: 1.
---@return string|nil @Material property name (like “ksDiffuse” or “ksAmbient”) or `nil` if there is no such element or property.
function _ac_SceneReference:getMaterialPropertyName(index, slotIndex) end

---Get index of a certain texture slot of an element from the name of that slot.
---@param index integer|nil @1-based index of an element to get an index of a texture slot of. Default value: 1.
---@param slotName string|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Name of a texture slot.
---@return integer|nil @1-based texture slot index, or `nil` if there is no such property.
---@overload fun(s: ac.SceneReference, slotName: string): integer|nil
function _ac_SceneReference:getTextureSlotIndex(index, slotName) end

---Get index of a certain material property of an element from the name of that property.
---@param index integer|nil @1-based index of an element to get an index of a material property of. Default value: 1.
---@param propertyName string|"'ksDiffuse'"|"'ksAmbient'"|"'ksEmissive'" @Name of material property.
---@return integer|nil @1-based material property index, or `nil` if there is no such property.
---@overload fun(s: ac.SceneReference, propertyName: string): integer|nil
function _ac_SceneReference:getMaterialPropertyIndex(index, propertyName) end

---Get texture filename of a certain texture slot of an element.
---@param index integer|nil @1-based index of an element to get a texture filename of. Default value: 1.
---@param slot string|integer|nil|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Texture slot name or a 1-based index of a texture slot. Default value: 1.
---@return string|nil @Texture filename or `nil` if there is no such slot or element.
---@overload fun(s: ac.SceneReference, slot: string): string
function _ac_SceneReference:getTextureSlotFilename(index, slot) end

---Dump shader replacements configs for materials in current selection. Resulting string might be pretty huge. Not all properties are dumped, but more properties might be added later. Some textures are stored as temporary IDs only valid within a session.
---@return string
function _ac_SceneReference:dumpShaderReplacements() end

---@param neck ac.SceneReference
---@param modelName string
---@param carIndex integer
---@return fun(value: number): number, number
function _ac_SceneReference:applyHumanMaterials(neck, modelName, carIndex) end

---Get value of a certain material property of an element.
---@param index integer|nil @1-based index of an element to get a material property of. Default value: 1.
---@param property string|integer|nil|"'ksDiffuse'"|"'ksAmbient'"|"'ksEmissive'" @Material property name or a 1-based index of a material property. Default value: 1.
---@return number|vec2|vec3|vec4|nil @Material property value (type depends on material property type), or `nil` if there is no such element or material property.
---@overload fun(s: ac.SceneReference, property: string): number|vec2|vec3|vec4|nil
function _ac_SceneReference:getMaterialPropertyValue(index, property) end

---Get number of materials in given scene reference (not recursive, only checks meshes and skinned meshes). If same material is used
---for two different meshes, it would only count once. Materials sharing same name can be different (for example, applying “[SHADER_REPLACEMENT_...]”
---via config to some meshes, not materials, forks their materials to not affect other meshes using the same material).
---@return integer @Number of materials.
function _ac_SceneReference:getMaterialsCount() end

---Creates a copy of a scene reference (not copies of nodes or meshes).
---@return ac.SceneReference
function _ac_SceneReference:clone() end

---Get bounding sphere of an element. Works only with meshes or skinned meshes, nodes will return nil.
---@param index integer|nil @1-based index of an element to get a bounding sphere of. Default value: 1.
---@param outVec vec3|nil @Optional vector to use for bounding sphere position, to avoid creating new vector.
---@return vec3|nil @Center of bounding sphere in parent node coordinates, or nil if there is no bounding sphere (if it’s not a mesh or a skinned mesh).
---@return number|nil @Radius of bounding sphere, or nil if there is no bounding sphere (if it’s not a mesh or a skinned mesh).
function _ac_SceneReference:boundingSphere(index, outVec) end

---Applies skin to nodes or meshes (if ran with nodes, will apply skin to all of their children meshes).
---Skin is a table storing texture names and filenames to skin textures. Example:
---```
---local skinDir = ac.getFolder(ac.FolderID.ContentCars) .. '/' .. ac.getCarID(0) .. '/skins/my_skin'
---ac.findNodes('carRoot:0'):applySkin({
---  ['metal_details.dds'] = skinDir .. '/metal_details.dds'
---})
---```
---@param skin table<string, string>
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:applySkin(skin) end

---Resets textures to ones from associated KN5 file where possible.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:resetSkin() end

---Change parent of nodes in current reference.
---@param parentSceneRef ac.SceneReference|nil @Set to nil to disconnect node from a scene.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setParent(parentSceneRef) end

---Finds materials in another scene reference that have the same names as materials in a given scene reference,
---and copies them over, so after that both references would share materials. Example use case: if you have LOD A and
---LOD B and LOD A got unique materials (because there are multiple objects sharing same KN5 model), with this function
---it’s possible to sync together materials from LOD A and LOD B by running `lodB:setMaterialsFrom(lodA)`. And because
---materials would not be actually copied, but instead shared, any consequent change of material properly in LOD A would
---be mirrored in LOD B.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setMaterialsFrom(materialSceneRef) end

---Creates a new scene reference with just a single item from the original scene reference.
---Indices are 1-based. By default it would create a new scene reference, if you need to access
---a lot of objects fast, provide your own:
---```
---  local meshes = ac.findMeshes('shader:ksTree')
---  local ref = ac.emptySceneReference()
---  for i = 1, #meshes do
---    meshes:at(i, ref)
---    print(ref:name())  -- note: for this particular case, it would be more optimal to use meshes:name(i) instead
---  end
---```
---@param index integer @1-based index.
---@param outSceneRef ac.SceneReference|nil
---@return ac.SceneReference @Reference to a child, might be empty if there is no such child.
function _ac_SceneReference:at(index, outSceneRef) end

---Returns number of nodes and meshes matching between this and another scene reference. Could be used to quickly find out if a certain element is in a set.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return integer
function _ac_SceneReference:countMatches(other) end

---Creates a new scene reference containing unique elements from both sets.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them.
---@return ac.SceneReference
function _ac_SceneReference:makeUnionWith(other) end

---Creates a new scene reference containing only the elements found in both of original sets.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return ac.SceneReference
function _ac_SceneReference:makeIntersectionWith(other) end

---Creates a new scene reference containing only the elements found in first set, but not in second set.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return ac.SceneReference
function _ac_SceneReference:makeSubtractionWith(other) end

---Create new fake shadow node. Uses the same shading as track fake shadows.
---@param params {points: vec3[], opacity: number, squaredness: vec2}|`{ points = {  }, opacity = 1, squaredness = vec2() }` "@Params for newly created node."
---@return ac.SceneReference @Reference to a newly created object.
function _ac_SceneReference:createFakeShadow(params) end

---Sets fake shadow points if current reference was created with `sceneReference:createFakeShadow()`.
---@param points vec3[] @Four corners.
---@param corners number[] @Four numbers for corner intensity.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowPoints(points, corners) end

---Sets fake shadow squaredness if current reference was created with `sceneReference:createFakeShadow()`.
---@param squaredness vec2 @X is squaredness along one axis, Y is along another.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowSquaredness(squaredness) end

---Sets fake shadow opacity if current reference was created with `sceneReference:createFakeShadow()`.
---@param opacity number @Value from 0 to 1.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowOpacity(opacity) end

---Applies shader replacements stored in INI config format. Can optionally load included files, so templates
---work as well. If there is no symbol “[” in `data`, applies passed values to all meshes and materials in selection.
---@param data string @Config in INIPP format.
---@param includeType ac.IncludeType? @Include type. If not set, includes will not be resolved, so templates won’t work. Default value: `ac.IncludeType.None`.
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:applyShaderReplacements(data, includeType) end

---Projects texture onto a mesh or few meshes, draws result. Use in when updating a dynamic texture, display or an extra canvas.
---Position, and directions are set in world space.
---
---Note: this is not a regular IMGUI drawing call, so most functions, such as shading offsets, transformations or clipping, would 
---not work here.
---
---Tip 1: if you want to draw a new skin for a car and apply AO to it, one way might be to draw it in a canvas and then draw
---original AO texture on top with special shading parameters:
---```
----- drawing rest of skin here
---ui.setShadingOffset(0, 0, 0, -1)
---ui.drawImage('car::EXT_body.dds', 0, ui.windowSize(), rgbm.colors.black)  -- with these shading offset properties, texture
---    -- will be drawn in black with inverse of brightness used for opacity
---ui.resetShadingOffset()
---```
---
---Tip 2: if you want to project things on meshes with certain material, make sure to filter out meshes so that it would only
---affect meshes from LOD A (instead of `ac.findMeshes('material:car_paint')` use `ac.findMeshes('{ material:car_paint & lod:A}')`),
---otherwise there’d be quite a few artifacts. I spent some time like this trying to figure out why results were off.
---@param params {filename: string, pos: vec3, look: vec3, up: vec3, color: rgbm, colorOffset: rgbm, size: vec2, depth: number, skew: vec2, tiling: vec2, doubleSided: boolean, uvOffset: vec2, blendMode: render.BlendMode, mask1: string, mask1UV1: vec2, mask1UV2: vec2, mask1Flags: render.TextureMaskFlags, mask2: string, mask2UV1: vec2, mask2UV2: vec2, mask2Flags: render.TextureMaskFlags}|`{filename = '', pos = vec3(), look = vec3(), up = vec3(0, 1, 0), color = rgbm.colors.white, size = vec2(), depth = 1e9, doubleSided = false}` "Table with properties:\n- `filename` (`string`): Path to a texture, or a texture element (`ui.MediaElement`, `ui.ExtraCanvas`, `ac.GeometryShot`).\n- `pos` (`vec3`): Position from which texture will be projected, in world space.\n- `look` (`vec3`): Direction with which texture will be projected, in world space.\n- `up` (`vec3`): Optional vector directed up, to specify texture rotation.\n- `color` (`rgbm`): Optional color. Default value: `rgbm.colors.white`.\n- `colorOffset` (`rgbm`): Optional color offset. Default value: `rgbm.colors.transparent`.\n- `size` (`vec2`): Size, horizontal and vertical. Default value: `vec2(1, 1)`.\n- `depth` (`number`): Depth: how far from camera projection goes, with a smooth falloff. Default value: 1e9.\n- `skew` (`vec2`): Optional skew. Default value: `vec2(0, 0)`.\n- `tiling` (`vec2`): Optional tiling for horizontal and vertical axis. With 1 tiles normally, with -1 tiles with flipping, other values are currently reserved. Default value: `vec2(0, 0)` (no tiling).\n- `doubleSided` (`boolean`): Set to `true` to draw things on surfaces facing away as well. Default value: `false`.\n- `uvOffset` (`vec2`): Optional UV offset. By default CSP estimates an UV offset such that most triagles would be shown. If mapping is way off though, it might need tweaking (or even repeated calls with different offsets).\n- `blendMode` (`render.BlendMode`): Optional override for blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `mask1` (`string`): Optional masking texture.\n- `mask1UV1` (`vec2`): Optional masking texture UV coordinates.\n- `mask1UV2` (`vec2`): Optional masking texture UV coordinates.\n- `mask1Flags` (`render.TextureMaskFlags`): Optional masking texture flags.\n- `mask2` (`string`): Optional secondary masking texture.\n- `mask2UV1` (`vec2`): Optional secondary masking texture UV coordinates.\n- `mask2UV2` (`vec2`): Optional secondary masking texture UV coordinates.\n- `mask2Flags` (`render.TextureMaskFlags`): Optional secondary masking texture flags."
---@return ac.SceneReference @Returns self for easy chaining.
function _ac_SceneReference:projectTexture(params) end

---Projects shader onto a mesh or few meshes, draws result. Use in when updating a dynamic texture, display or an extra canvas.
---Position, and directions are set in world space. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.      
---
---Example:
---```
---local ray = render.createMouseRay()
---meshes:projectShader({
---  async = true,
---  pos = ray.pos,
---  look = ray.dir,
---  blendMode = render.BlendMode.Opaque,
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) { 
---      if (dot(abs(pin.Tex * 2 - 1), 1) > 0.5) return 0;
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return gFlag ? pin.NormalView * in1 + in2 * gValueColor : in2;
---    }
---  ]]
---})
---```
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC 
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {pos: vec3, look: vec3, up: vec3, size: vec2, withDepth: boolean, expanded: boolean, uvOffset: vec2, blendMode: render.BlendMode, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{pos = vec3(), look = vec3(), up = vec3(0, 1, 0), size = vec2(), withDepth = true, expanded = true, blendMode = render.BlendMode.BlendAccurate, textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `pos` (`vec3`): Position from which texture will be projected, in world space.\n- `look` (`vec3`): Direction with which texture will be projected, in world space.\n- `up` (`vec3`): Optional vector directed up, to specify texture rotation.\n- `size` (`vec2`): Size, horizontal and vertical. Default value: `vec2(1, 1)`.\n- `withDepth` (`boolean`): If depth is used, nearest to projection position triagles will have higher priority (in case of overlapping UV), slightly slower, but produces better results (especially with `expanded` set to `true`).\n- `expanded` (`boolean`): Draws each mesh four additional times with small offsets to fill partically covered pixels. More expensive (but less expensive comparing to fixing issue with those half covered pixels with additional draw calls via Lua).\n- `uvOffset` (`vec2`): Optional UV offset. By default CSP estimates an UV offset such that most triagles would be shown. If mapping is way off though, it might need tweaking (or even repeated calls with different offsets).\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/project.fx” (look into it to see what fields are available)."
function _ac_SceneReference:projectShader(params) end

---@return ac.SceneReference
function ac.emptySceneReference() end

---Creates a new scene reference containing objects (nodes, meshes, etc.) collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Node: for most cases, using `ac.findNodes()`, `ac.findMeshes()` and similar would work better.
---@param s string @Node/mesh filter.
---@return ac.SceneReference
function ac.findAny(s) end

---Creates a new scene reference containing nodes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Just a reminder, nodes refer to parent objects. Themselves, don’t get rendered, only their children elements (which might be nodes or meshes), but they can move.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual. There are also some special keywords available:
---- `'luaRoot:yes'`: root node associated with current script.
---- `'sceneRoot:yes'`: the most root node (do not add your objects here, they won’t be drawn properly).
---- `'carsRoot:yes'`: node that hosts all the cars. If you want to load custom dynamic objects, especially complex, it’s recommended to load them in bounding sphere and attach here (this node is optimized to render bounding sphere-wrapped objects quickly).
---- `'trackRoot:yes'`: track root node.
---- `'staticRoot:yes'`: node with static geometry (affected by motion blur from original AC).
---- `'dynamicRoot:yes'`: node with dynamic geometry (node affected by motion blur from original AC).
---
---Note: if you’re adding new objects to a car, seach for `'BODYTR'` node. Car root remains stationary and hosts “BODYTR” for main car model and things like wheels and suspension nodes.
---@param s string @Node filter.
---@return ac.SceneReference
function ac.findNodes(s) end

---Creates a new scene reference containing meshes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Just as a reminder, meshes can’t move. If you want to move a mesh, find its parent node and move it. If parent node has more than a single mesh, you can create a new parent node and move
---mesh found with `ac.findMeshes()` there.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findMeshes(s) end

---Creates a new scene reference containing skinned meshes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findSkinnedMeshes(s) end

---Creates a new scene reference containing objects of a certain class collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param objectClass ac.ObjectClass @Objects class.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findByClass(objectClass, s) end
