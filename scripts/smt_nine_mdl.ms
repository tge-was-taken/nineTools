-- Config
global cfg_EnableSkin = true;

-- Globals
global g_ioContext = undefined;

-- Functions

-- Cache commonly used interface functions
global _bit_SwapBytes = bit.SwapBytes;
global _bit_And = bit.And;
global _bit_IntAsFloat = bit.IntAsFloat;
global _bit_Get = bit.Get;
global _bit_IntAsChar = bit.intAsChar;
global _bonesys_createbone = bonesys.createbone;
global _skinOps_AddBone = skinOps.AddBone;
global _modPanel_SetCurrentObject = modPanel.SetCurrentObject;
global _skinOps_ReplaceVertexWeights = skinOps.ReplaceVertexWeights;
global _skinOps_SetVertexWeights = skinOps.SetVertexWeights;

-- Utility
fn utilSwap16 value =
(
    _bit_SwapBytes value 1 2
)

fn utilSwap32 value =
(
    _bit_SwapBytes ( _bit_SwapBytes value 1 4 ) 2 3
)

fn utilSwapFloat value =
(
    _bit_IntAsFloat ( _bit_SwapBytes ( _bit_SwapBytes value 1 4 ) 2 3 )
)

fn utilAllBitsSet value mask =
(
    ( _bit_And value mask ) == mask;
)

fn utilInitList count  =
(
    local list = #();
	
	if ( count > 0 ) then
		list[count] = undefined;
	
    list;
)

fn utilVector3YToZUp value =
(
    local temp = value.Y;
    value.Y = -value.Z;
    value.Z = temp;   
    value;
)

-- File IO
ioEndian_Little = 0
ioEndian_Big = 1

struct ioContext
(
    Stream,
    FileName,
    FilePath,
    Endianness,
    Swap,
    BasePositions,
	BasePositionIndex,
	BasePosition,
    SavedPositions,
	SavedPositionIndex
)

fn ioOpenFile filePath =
(
    g_ioContext = ioContext();
    g_ioContext.Stream = fopen filePath #rb;
    g_ioContext.FileName = GetFilenameFile filePath;
    g_ioContext.FilePath = GetFilenamePath filePath;
    g_ioContext.Endianness = ioEndian_Little;
    g_ioContext.Swap = false;
	g_ioContext.BasePositions = #( 0 );
    g_ioContext.BasePositionIndex = 1;
	g_ioContext.BasePosition = 0;
	g_ioContext.SavedPositions = #();
    g_ioContext.SavedPositionIndex = 0;
)

fn ioSelectOpenFile category ext =
(
    local typesStr = category + "(*." + ext[1];
    for i = 2 to ext.Count do
    (
        typesStr += ",*." + ext[i];
    )
    typesStr += ")|*." + ext[1];
    for i = 2 to ext.Count do
    (
        typesStr += ";*." + ext[i];
    )
    
    local filePath = getOpenFileName \ 
        caption:("Open " + category + " file")\
        types:typesStr \
        historyCategory:( category + " Object Presets" )
    
    filePath;
)

fn ioGetFileName =
(
    g_ioContext.FileName;
)

fn ioGetFilePath =
(
    g_ioContext.FilePath;
)

fn ioSetEndianness endian =
(
    g_ioContext.Endianness = endian;
    g_ioContext.Swap = g_ioContext.Endianness == ioEndian_Big;
)

fn ioTell =
(
    FTell g_ioContext.Stream;
)

fn ioPushBase =
(
	g_ioContext.BasePositionIndex += 1;
	g_ioContext.BasePosition = g_ioContext.BasePositions[ g_ioContext.BasePositionIndex ] = ioTell();
)

fn ioPush =
(
	--print( "ioPush (0x" + ( bit.intashex(ioTell()) as string ) + ")" );
	g_ioContext.SavedPositionIndex += 1;
    g_ioContext.SavedPositions[ g_ioContext.SavedPositionIndex ] = ioTell();
)

fn ioPopBase =
(
	g_ioContext.BasePositionIndex -= 1;
	g_ioContext.BasePosition = g_ioContext.BasePositions[ g_ioContext.BasePositionIndex ];
)

fn ioSeekSetAbs position = ()

fn ioPop =
(
	--print( "ioPop (0x" + ( bit.intashex(ioTell()) as string ) + ")" );
	local savedPosition = g_ioContext.SavedPositions[ g_ioContext.SavedPositionIndex ];
	g_ioContext.SavedPositionIndex -= 1;
    ioSeekSetAbs( savedPosition );
)

fn ioSeekCur position =
(
    FSeek g_ioContext.Stream position #seek_cur;
)

fn ioSeekSetAbs position =
(
    FSeek g_ioContext.Stream position #seek_set;
)

fn ioSeekSet position =
(
    FSeek g_ioContext.Stream ( g_ioContext.BasePosition + position ) #seek_set;
)

fn ioReadU8 =
(
    ReadByte g_ioContext.Stream #unsigned;
)

fn ioReadS16 =
(
    local value = ReadShort g_ioContext.Stream #signed;
    if ( g_ioContext.Swap ) then value = utilSwap16( value );
    value;
)

fn ioReadU16 =
(
    local value = ReadShort g_ioContext.Stream #unsigned;
    if ( g_ioContext.Swap ) then value = utilSwap16( value );
    value;
)

fn ioReadS32 =
(
    local value = ReadLong g_ioContext.Stream #signed;
    if ( g_ioContext.Swap ) then value = utilSwap32( value );
    value;
)

fn ioReadU32 =
(
    local value = ReadLong g_ioContext.Stream #unsigned;
    if ( g_ioContext.Swap ) then value = utilSwap32( value );
    value;
)

fn ioReadF32 =
(
    local value;
    if ( g_ioContext.Swap ) then value = _bit_IntAsFloat( ioReadU32() );
    else value = ReadFloat g_ioContext.Stream;
    value;
)

fn ioReadTexCoord =
(
    [ ioReadF32(), 1f - ioReadF32(), 0 ];
)

fn ioReadVector2 =
(
    [ ioReadF32(), ioReadF32() ];
)

fn ioReadVector3 =
(
    [ ioReadF32(), ioReadF32(), ioReadF32() ];
)

fn ioReadVector4 =
(
    [ ioReadF32(), ioReadF32(), ioReadF32(), ioReadF32() ];
)

fn ioReadQuaternion =
(
    quat (ioReadF32()) (ioReadF32()) (ioReadF32()) (ioReadF32());
)

fn ioReadString =
(
    ReadString g_ioContext.Stream;
)

struct nineAsset
(
    Magic,
    Version,
    Field08,
    Field0C,
    ContentOffset,
    Content
)

struct nineModel
(
    Field00,
    VertexBufferSize,
    TextureReferenceCount,
    SkinBoneCount,
    RootNodeOffset,
    VertexBufferOffset,
    TextureReferencesOffset,
    SkinBoneMapOffset,
    Field20,
    Field24,
    Field28,
    Field2C,
    Field30,
    RootNode,
    TextureReferences,
    SkinBoneMap = #()
)

struct nineNode
(
    ChildCount,
    MeshCount,
    ChildOffsetListOffset,
    MeshListOffset,
    Position,
    Rotation,
    Scale,
    Field38,
    Field3C,
    Field40,
    Field44,
    Field48,
    Children = #(),
    Meshes = #(),
    MaxBone
)

struct nineMesh
(
    Field00, -- 1
    IndexCount,
    VertexCount,
    VertexStartOffset, -- Relative offset
    VertexStride,
    VertexFlags, -- 0x23, 0x623 
    BoundingBoxMaybe,
    MaterialOffset, 
    IndexStartOffset,
    Field4C, -- 1
    Field4E, -- 1
    IndexStartOffset2, -- same as IndexStartOffset
    Field54, -- 0
    Field58, -- 1
    Field5C, -- 0
    Field60, -- 0
    Field64,
    VertexPositions = #(),
    VertexNormals = #(),
    VertexUVs = #(),
    VertexBlendWeights = #(),
    VertexBlendIndices = #(),
    Triangles = #(),
    Material,
    MaxMesh
)

struct nineMaterial
(
    TextureIndex
)

fn nineMeshesRead count vertexBufferOffset textureReferences =
(
    local meshes = #();
    for i = 1 to count do
    (
        local m = nineMesh();
        m.Field00 = ioReadU32(); -- 1
        m.IndexCount = ioReadU32();
        m.VertexCount = ioReadU32();
        m.VertexStartOffset = ioReadU32(); -- Relative offset
        m.VertexStride = ioReadU16();
        m.VertexFlags = ioReadU16(); -- 0x23 = ioReadU32(); 0x623 
        ioSeekCur( 12 * 4 );
        m.MaterialOffset = ioReadU32(); 
        m.IndexStartOffset = ioReadU32();
        m.Field4C = ioReadU16(); -- 1
        m.Field4E = ioReadU16(); -- 1
        m.IndexStartOffset2 = ioReadU32(); -- same as IndexStartOffset
        m.Field54 = ioReadU32(); -- 0
        m.Field58 = ioReadU32(); -- 1
        m.Field5C = ioReadU32(); -- 0
        m.Field60 = ioReadU32(); -- 0
        m.Field64 = ioReadU32();
        
        --Assert( m.IndexStartOffset == m.IndexStartOffset2 );

        if ( vertexBufferOffset != 0 and m.VertexCount != 0 ) then
        (
            ioPush();
            ioSeekSet( vertexBufferOffset + m.VertexStartOffset );
            (
                case ( m.VertexStride ) of
                (
                    24:
                    for j = 1 to m.VertexCount do
                    (
                        m.VertexPositions[j] = ioReadVector3();
                        m.VertexNormals[j] = ioReadVector3();
                        m.VertexUVs[j] = [0,0,0];
                    )
                    
                    32:
                    for j = 1 to m.VertexCount do
                    (
                        m.VertexPositions[j] = ioReadVector3();
                        m.VertexNormals[j] = ioReadVector3();
                        m.VertexUVs[j] = ioReadTexCoord();
                    )
            
                    52:
                    for j = 1 to m.VertexCount do
                    (
                        m.VertexPositions[j] = ioReadVector3();
                        m.VertexNormals[j] = ioReadVector3();
                        
                        local blendWeights = #();
                        for k = 1 to 4 do
                            blendWeights[k] = ioReadF32();
                        
                        m.VertexBlendWeights[j] = blendWeights;
                        
                        local blendIndices = #();
                        for k = 1 to 4 do
                            blendIndices[k] = ioReadU8() + 1;
                        
                        m.VertexBlendIndices[j] = blendIndices;
                        m.VertexUVs[j] = ioReadTexCoord();
                    )
            
                    default: ();
                )
            )
            ioPop();
        )

        if ( m.IndexStartOffset != 0 and m.IndexCount != 0 ) then
        (
            ioPush();
            ioSeekSet( m.IndexStartOffset );
            m.Triangles = #();
            
            local a = ioReadU16() + 1;
            local b = ioReadU16() + 1;
            local direction = -1;
            for j = 1 to m.IndexCount - 2 do
            (
                local c = ioReadU16() + 1;
                
                direction *= -1;
                if ( a != b ) and ( b != c ) and ( c != a ) then 
                (
                    if direction == 1 then append m.Triangles [a, b, c];
                    else append m.Triangles [a, c, b];
                )
                
                a = b;
                b = c;
            )
            ioPop();
        )
        
        if ( m.MaterialOffset != 0 ) then
        (
            ioPush();
            ioSeekSet( m.MaterialOffset );
            m.Material = nineMaterial();
            m.Material.TextureIndex = ioReadU32() + 1;
            ioPop();
        )
        
        m.MaxMesh = mesh vertices:m.VertexPositions normals:m.VertexNormals faces:m.Triangles;
        
        -- Set up texture coordinates
        m.MaxMesh.NumTVerts = m.VertexCount;
        buildTVFaces m.MaxMesh;
        for j = 1 to m.Triangles.Count do setTVFace m.MaxMesh j m.Triangles[j];
        for j = 1 to m.VertexUVs.Count do setTVert m.MaxMesh j m.VertexUVs[j];
            
        -- Set up material
        if ( m.Material != undefined ) then
        (
            local textureName = textureReferences[m.Material.TextureIndex];
            m.MaxMesh.Material = standard();
            m.MaxMesh.Material.Name = textureName + "_material";
            m.MaxMesh.Material.DiffuseMap = Bitmaptexture filename:( ioGetFilePath() + "..\\textures\\" + textureName );
            m.MaxMesh.Material.ShowinViewport = true; 
            m.MaxMesh.BackFaceCull = on;
        )
        
        meshes[i] = m;
    )
    
    meshes;
)

fn nineNodeRead parent vertexBufferOffset textureReferences &nodes =
(
    local n = nineNode();
    append nodes n;
    n.ChildCount = ioReadU32();
    n.MeshCount = ioReadU32();
    n.ChildOffsetListOffset = ioReadU32();
    n.MeshListOffset = ioReadU32();
    n.Position = ioReadVector3();
    n.Rotation = ioReadQuaternion();
    n.Scale = ioReadVector3();
    n.Field38 = ioReadU32();
    n.Field3C = ioReadU32();
    n.Field40 = ioReadU32();
    n.Field44 = ioReadU32();
    n.Field48 = ioReadU32(); 
    
    local tfm = (Inverse n.Rotation) as matrix3;
        tfm *= ScaleMatrix n.Scale;
        tfm.row4 = n.Position;
    
    if ( parent != undefined ) then
    (
        tfm *= parent.MaxBone.transform;
    )
    
    n.MaxBone = _bonesys_createbone \
              tfm.row4	\
              (tfm.row4 + 0.01 * (normalize tfm.row1)) \
              (normalize tfm.row3);
                      
    --n.MaxBone.name = node.Name;
    n.MaxBone.width  = 0.001;
    n.MaxBone.height = 0.001;
    n.MaxBone.transform = tfm;
    n.MaxBone.setBoneEnable false 0;
    n.MaxBone.wirecolor = yellow;
    n.MaxBone.showlinks = true;
    n.MaxBone.pos.controller      = TCB_position ();
    n.MaxBone.rotation.controller = TCB_rotation ();
    if ( parent != undefined ) then
    (
        n.MaxBone.Parent = parent.MaxBone;
    )
    
    if ( n.MeshListOffset != 0 and n.MeshCount != 0 ) then
    (
        ioPush();
        ioSeekSet( n.MeshListOffset );
        n.Meshes = nineMeshesRead n.MeshCount vertexBufferOffset textureReferences;
        for m in n.Meshes do
        (
            m.MaxMesh.Transform = n.MaxBone.Transform;
            m.MaxMesh.Parent = n.MaxBone;
        )
        ioPop();
    )

    if ( n.ChildOffsetListOffset != 0 ) then
    (
        ioPush();
        ioSeekSet( n.ChildOffsetListOffset );
        (
            for i = 1 to n.ChildCount do
            (
                local childOffset = ioReadU32();
                ioPush();
                ioSeekSet( childOffset );
                append n.Children (nineNodeRead n vertexBufferOffset textureReferences &nodes);
                ioPop();  
            )
        )
        
        ioPop();
    )

    n;
)

fn nineTextureReferencesRead count =
(
    local textureReferences = #();
    for i = 1 to count do
    (
        local textureNameOffset = ioReadU32();
        local field04 = ioReadU32();
        local textureName = undefined;
        if ( textureNameOffset != 0 ) then
        (
            ioPush();
            ioSeekSet( TextureNameOffset );
            textureName = ioReadString();
            ioPop();
        )
        
        textureReferences[i] = textureName;
    )
    
    textureReferences;
)

fn nineModelRead =
(
    local mdl = nineModel();
    mdl.Field00 = ioReadU32();
    mdl.VertexBufferSize = ioReadU32();
    mdl.TextureReferenceCount = ioReadU32();
    mdl.SkinBoneCount = ioReadU32();
    mdl.RootNodeOffset = ioReadU32();
    mdl.VertexBufferOffset = ioReadU32();
    mdl.TextureReferencesOffset = ioReadU32();
    mdl.SkinBoneMapOffset = ioReadU32();
    mdl.Field20 = ioReadU32();
    mdl.Field24 = ioReadU32();
    mdl.Field28 = ioReadU32();
    mdl.Field2C = ioReadU32();
    mdl.Field30 = ioReadU32();
    
    if ( mdl.TextureReferencesOffset != 0 ) then
    (
        ioPush();
        ioSeekSet( mdl.TextureReferencesOffset );
        mdl.TextureReferences = nineTextureReferencesRead( mdl.TextureReferenceCount );
        ioPop();
    )
    
    local nodes = #();
    
    if ( mdl.RootNodeOffset != 0 ) then
    (
        ioPush();
        ioSeekSet( mdl.RootNodeOffset );
        mdl.RootNode = nineNodeRead undefined mdl.VertexBufferOffset mdl.TextureReferences &nodes;
        ioPop();
    )
    
    if ( mdl.SkinBoneMapOffset != 0 ) then
    (
        ioPush();
        ioSeekSet( mdl.SkinBoneMapOffset );
        for i = 1 to mdl.SkinBoneCount do
        (
            mdl.SkinBoneMap[i] = ioReadU32();
        )
        ioPop();
    )
    
    -- Set up weights
    if ( cfg_EnableSkin ) then
    (
        for n in nodes do
        (
            for m in n.Meshes do
            (
                if ( m.VertexBlendWeights.Count > 0 ) then 
                (                
                    resumeEditing();
                    max modify mode;
                    
                    select m.MaxMesh;
                    local skinMod = skin();
                    addModifier m.MaxMesh skinMod;
                    
                    -- Add used bones to the skin modifier
                    for j = 1 to mdl.SkinBoneMap.Count do
                    (
                        _skinOps_AddBone skinMod nodes[mdl.SkinBoneMap[j]].MaxBone 0;
                    )
                    
                    _modPanel_SetCurrentObject skinMod;
                    for j = 1 to m.VertexCount do
                       _skinOps_ReplaceVertexWeights skinMod j m.VertexBlendIndices[j] m.VertexBlendWeights[j];
                )   
            )
        )
    )
    
    m;
)

fn nineAssetRead =
(
    ioPushBase();
    
    local a = nineAsset();
    a.Magic = ioReadU32();
    a.Version = ioReadU32();
    a.Field08 = ioReadU32();
    a.Field0C = ioReadU32();
    a.ContentOffset = ioReadU32();
    
    if ( a.ContentOffset != 0 ) then
    (
        ioPush();
        ioSeekSet( a.ContentOffset );
        case ( a.Magic ) of
        (
            0x004C444D: a.Content = nineModelRead();
        )
        ioPop();
    )
    
    ioPopBase();
    
    a;
)

fn nineArchiveRead =
(
    local lowestOffset = 0x7FFFFFFF;

    while ( true ) do
    (
        if ( ioTell() >= lowestOffset ) then
            exit;
    
        local offset = ioReadU32();
        local size = ioReadU32();

        if ( offset != 0 and size != 0 ) then
        (
            ioPush();
            ioSeekSet( offset );
            local asset = nineAssetRead();
            ioPop();
        )

        if ( offset < lowestOffset ) then
            lowestOffset = offset;
    )
)


fn main =
(
	clearListener();
	
	--local filePath = @"D:\Users\smart\Desktop\s013.bin.1.mdl";
    --local filePath = @"D:\Users\smart\Downloads\SMT NINE Models\Models\item\ITEMALL.BIN";
	local filePath = ioSelectOpenFile "SMT NINE model" #("BIN", "MMX");
	if ( filePath != undefined ) then
	(
        ioOpenFile( filePath );
        
        local ext = getFilenameType( filePath );
        if ( ext == ".BIN" ) then
        (
            nineArchiveRead();
        )
        else if ( ext == ".MMX" ) then
        (
            nineAssetRead();
        )
	)
	
	OK
)

main();