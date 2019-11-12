using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace nineTexSplit
{
    class Program
    {
        static void Main( string[] args )
        {
            if ( args.Length == 0 )
            {
                Console.WriteLine( "nineTexSplit by TGE (2019)");
                Console.WriteLine( "Splits SMT NINE .tex files" );
                Console.WriteLine();
                Console.WriteLine( "Error: Missing path to .tex file" );
                return; 
            }

            var path = args[0];
            var outDirectoryPath = Path.Combine( Path.GetDirectoryName( path ), Path.GetFileNameWithoutExtension( path ) );
            Directory.CreateDirectory( outDirectoryPath );

            using ( var reader = new BinaryReader( File.OpenRead( args[0] ) ) )
            {
                var magic = reader.ReadInt32();
                if ( magic != 0x4E494F4A )
                {
                    Console.WriteLine( "Invalid tex file" );
                    return;
                }

                var textureCount = reader.ReadInt32();
                reader.BaseStream.Seek( 8, SeekOrigin.Current );

                for ( int i = 0; i < textureCount; i++ )
                {
                    var offset = reader.ReadInt32();
                    var size = reader.ReadInt32();
                    reader.BaseStream.Seek( 8, SeekOrigin.Current );
                    var name = Encoding.ASCII.GetString( reader.ReadBytes( 32 ) ).Replace( "\0", string.Empty );

                    var nextEntry = reader.BaseStream.Position;
                    reader.BaseStream.Seek( offset, SeekOrigin.Begin );
                    File.WriteAllBytes( Path.Combine( outDirectoryPath, name ), reader.ReadBytes( size ) );
                    reader.BaseStream.Seek( nextEntry, SeekOrigin.Begin );
                }
            }
        }
    }
}
