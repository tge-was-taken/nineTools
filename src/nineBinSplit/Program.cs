using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace nineBinSplit
{
    class Program
    {
        static void Main( string[] args )
        {
            if ( args.Length == 0 )
            {
                Console.WriteLine( "nineBinSplit by TGE (2019)" );
                Console.WriteLine( "Splits SMT NINE .BIN files" );
                Console.WriteLine();
                Console.WriteLine( "Error: Missing path to .BIN file" );
                return;
            }

            var path = args[0];
            var fileName = Path.GetFileNameWithoutExtension( path );
            var outDirectoryPath = Path.Combine( Path.GetDirectoryName( path ), fileName );
            Directory.CreateDirectory( outDirectoryPath );

            var fileIndex = 0;

            using ( var reader = new BinaryReader( File.OpenRead( args[0] ) ) )
            {
                var lowestOffset = int.MaxValue;
                while ( true )
                {
                    if ( reader.BaseStream.Position >= lowestOffset )
                        break;

                    var offset = reader.ReadInt32();
                    var size = reader.ReadInt32();

                    if ( offset != 0 && size != 0 )
                    {
                        var nextEntry = reader.BaseStream.Position;
                        reader.BaseStream.Seek( offset, SeekOrigin.Begin );
                        var magic = Encoding.ASCII.GetString( reader.ReadBytes( 3 ) );
                        reader.BaseStream.Seek( offset, SeekOrigin.Begin );

                        var name = fileName + "_" + fileIndex;
                        if ( magic == "MDL" )
                            name += ".MMX";
                        else if ( magic == "MOT" )
                            name += ".MOT";
                        else if ( magic == "DDS" )
                            name += ".DDS";
                        else if ( magic == "JOI" )
                            name += ".TEX";
                        else
                            name += ".BIN";

                        File.WriteAllBytes( Path.Combine( outDirectoryPath, name ), reader.ReadBytes( size ) );
                        reader.BaseStream.Seek( nextEntry, SeekOrigin.Begin );
                    }

                    if ( offset < lowestOffset )
                        lowestOffset = offset;

                    ++fileIndex;
                }
            }
        }
    }
}
