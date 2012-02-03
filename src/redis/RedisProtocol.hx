/**
 Copyright (c) 2010 SoybeanSoft

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *
 * haXe/Neko RedisAPI
 * @author Ian Martins
 */

package redis;

import haxe.io.Input;
import haxe.io.Output;

class RedisProtocol
{
  private static var EOL = "\r\n";
  private var input :Input;
  private var output :Output;

  public function new(input, output)
  {
    this.input = input;
    this.output = output;
  }

  private function sendBulkArg(arg :String)
  {
    return "$" + arg.length + EOL + arg + EOL;
  }

  public function sendMultiBulkCommand(cmd :String, args :Array<String>)
  {
    var sb = new StringBuf();
    sb.add("*" + (args.length+1) + EOL);
    sb.add(sendBulkArg(cmd));
    for( ii in args )
      sb.add(sendBulkArg(ii));
    output.writeString(sb.toString());
  }

  public function receiveSingleLine() :String
  { 
    var line = input.readLine();
    if( line.charAt(0) == "-" )
      throw new RedisError(line);

    return line.substr(1);
    }

  public function receiveBulk() :String
  { 
    var line = input.readLine();
    if( line.charAt(0) == "-" )
      throw new RedisError(line);
    
    var len = Std.parseInt(line.substr(1));
    if( len==-1 )
      return null;

    var ret = input.read(len).toString();
    if( ret.length != len )
      throw new RedisError("-ERR response length mismatch");
    input.read(2);

    return ret;
  }

  public function receiveMultiBulk() :Array<String>
  {
    var ret = new Array<String>();

    var line = input.readLine();
    if( line.charAt(0) == "-" )
      throw new RedisError(line);

    var count = Std.parseInt(line.substr(1));
    if( count==-1 )
      return null;
    
    for( cc in 0...count )
      ret.push(receiveBulk());

    return ret;
  }

  public function receiveInt() :Int
  { 
    var line = input.readLine();
    if( line.charAt(0) == "-" )
      throw new RedisError(line);

    return Std.parseInt(line.substr(1));
  }
}
