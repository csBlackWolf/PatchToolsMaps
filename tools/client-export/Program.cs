using System.Text.Json;
using DBCD.Providers;
using TACTSharp;

var folder=Path.GetFullPath(args[0]);
var clientVersion=args.Length>4 ? args[4] : "1.60.1.70532";
if(args.Length>1 && (args[1]=="extract" || args[1]=="verify-textures")) {
    if(args.Length<4) throw new ArgumentException("Usage: MapExtract <output folder> extract|verify-textures <game root> <product>");
    var gameRoot=Path.GetFullPath(args[2]);
    var product=args[3];
    var info=File.ReadAllLines(Path.Combine(gameRoot,".build.info"));
    var fields=info[0].Split('|').Select(s=>s.Split('!')[0]).ToArray();
    var productIndex=Array.IndexOf(fields,"Product");
    var config=info.Skip(1).Select(s=>s.Split('|')).First(r=>r.Length>productIndex && r[productIndex]==product);
    clientVersion=config[Array.IndexOf(fields,"Version")];
    var build=new BuildInstance();
    build.Settings.BaseDir=gameRoot;
    build.Settings.Product=product;
    build.Settings.TryCDN=false;
    build.Settings.ListfileFallback=false;
    build.Settings.CacheDir=Path.Combine(folder,"cache");
    build.LoadConfigs(config[Array.IndexOf(fields,"Build Key")],config[Array.IndexOf(fields,"CDN Key")]);
    build.Load();
    File.WriteAllText(Path.Combine(folder,"extraction-meta.json"),JsonSerializer.Serialize(new {
        version=clientVersion,product,buildConfig=config[Array.IndexOf(fields,"Build Key")],
        cdnConfig=config[Array.IndexOf(fields,"CDN Key")],localOnly=true
    }));
    if(args[1]=="verify-textures") {
        var tiles=JsonDocument.Parse(File.ReadAllText(Path.Combine(folder,"WorldMapOverlayTile.json")));
        var checkedTextures=new List<object>();
        foreach(var id in tiles.RootElement.EnumerateArray().Select(r=>r.GetProperty("FileDataID").GetUInt32()).Distinct().Order()) {
            var bytes=build.OpenFileByFDID(id);
            var magic=System.Text.Encoding.ASCII.GetString(bytes,0,4);
            if(magic!="BLP2") throw new Exception($"Unexpected texture format {magic} for {id}");
            checkedTextures.Add(new {id,width=BitConverter.ToUInt32(bytes,12),height=BitConverter.ToUInt32(bytes,16)});
        }
        File.WriteAllText(Path.Combine(folder,"texture-headers.json"),JsonSerializer.Serialize(checkedTextures));
        Console.WriteLine($"Verified {checkedTextures.Count} client texture headers (no images written)");
        return;
    }
    foreach(var line in File.ReadAllLines(Path.Combine(folder,"extract.txt"))) {
        var parts=line.Split(';');
        var bytes=build.OpenFileByFDID(uint.Parse(parts[0]));
        File.WriteAllBytes(Path.Combine(folder,parts[1]),bytes);
        Console.WriteLine($"Extracted {parts[1]}: {bytes.Length} bytes");
    }
}
var reader=new DBCD.DBCD(new FilesystemDBCProvider(folder),new FilesystemDBDProvider(Path.Combine(folder,"definitions")));
foreach(var line in File.ReadAllLines(Path.Combine(folder,"extract.txt"))) {
    var name=Path.GetFileNameWithoutExtension(line.Split(';')[1]);
    var storage=reader.Load(name,clientVersion);
    var records=new List<Dictionary<string,object>>();
    foreach(var row in storage.Values) {
        var record=new Dictionary<string,object>();
        foreach(var field in row.GetDynamicMemberNames()) record[field]=row[field];
        records.Add(record);
    }
    File.WriteAllText(Path.Combine(folder,name+".json"),JsonSerializer.Serialize(records));
    Console.WriteLine($"Decoded {name}: {records.Count} records");
}
