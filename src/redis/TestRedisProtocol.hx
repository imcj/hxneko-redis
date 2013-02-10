/**
   Copyright (c) 2010-2013 SoybeanSoft, Ian Martins

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

import haxe.io.BytesOutput;
import haxe.io.BytesInput;
import haxe.io.Bytes;

class TestRedisProtocol extends haxe.unit.TestCase
{
    public function testSendMultiBulk1()
    {
        var output = new BytesOutput();
        var proto = new RedisProtocol(null, output);
        proto.sendMultiBulkCommand("SET", ["somekey", "someval"]);
        assertEquals("*3\r\n$3\r\nSET\r\n$7\r\nsomekey\r\n$7\r\nsomeval\r\n", output.getBytes().toString());
    }

    public function testReceiveSingleLine1()
    {
        var input = new BytesInput(Bytes.ofString("+PONG\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("PONG", proto.receiveSingleLine());
    }

    public function testReceiveSingleLine2()
    {
        var input = new BytesInput(Bytes.ofString("+OK\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("OK", proto.receiveSingleLine());
    }

    public function testReceiveSingleLineError()
    {
        var input = new BytesInput(Bytes.ofString("-ERR it didn't work\r\n"));
        var proto = new RedisProtocol(input, null);
        try
        {
            proto.receiveSingleLine();
            assertTrue(false);
        }
        catch (e :RedisError)
        {
            assertTrue(true);
        }
    }

    public function testReceiveBulk1()
    {
        var input = new BytesInput(Bytes.ofString("$6\r\nfoobar\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("foobar", proto.receiveBulk());
    }

    public function testReceiveBulk2()
    {
        var input = new BytesInput(Bytes.ofString("$11\r\nfoo bar foo\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("foo bar foo", proto.receiveBulk());
    }

    public function testReceiveBulk3()
    {
        var input = new BytesInput(Bytes.ofString("$-1\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals(null, proto.receiveBulk());
    }

    public function testReceiveBulkBinary()
    {
        var input = new BytesInput(Bytes.ofString("$8\r\nfoo\r\nbar\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("foo\r\nbar", proto.receiveBulk());
    }


    public function testReceiveBulkError1()
    {
        var input = new BytesInput(Bytes.ofString("$7\r\nfoobar\r\n"));
        var proto = new RedisProtocol(input, null);
        try
        {
            proto.receiveBulk();
            assertTrue(false);
        }
        catch (e :haxe.io.Eof)
        {
            assertTrue(true);
        }
        catch (e2 :Dynamic)
        {
            assertTrue(false);
        }
    }

    public function testReceiveBulkError2()
    {
        var input = new BytesInput(Bytes.ofString("-ERROR\r\n"));
        var proto = new RedisProtocol(input, null);
        try
        {
            proto.receiveBulk();
            assertTrue(false);
        }
        catch (e :RedisError)
        {
            assertTrue(true);
        }
    }

    public function testReceiveMultiBulk1()
    {
        var input = new BytesInput(Bytes.ofString("*4\r\n$3\r\nfoo\r\n$3\r\nbar\r\n$5\r\nHello\r\n$5\r\nWorld\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("[foo,bar,Hello,World]", Std.string(proto.receiveMultiBulk()));
    }

    public function testReceiveMultiBulk2()
    {
        var input = new BytesInput(Bytes.ofString("*4\r\n$3\r\nfoo\r\n$3\r\nbar\r\n$-1\r\n$5\r\nWorld\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals("[foo,bar,null,World]", Std.string(proto.receiveMultiBulk()));
    }

    public function testReceiveMultiBulk3()
    {
        var input = new BytesInput(Bytes.ofString("*-1\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals(null, proto.receiveMultiBulk());
    }

    public function testReceiveMultiBulkError()
    {
        var input = new BytesInput(Bytes.ofString("-ERROR\r\n"));
        var proto = new RedisProtocol(input, null);
        try
        {
            proto.receiveMultiBulk();
            assertTrue(false);
        }
        catch (e :RedisError)
        {
            assertTrue(true);
        }
    }

    public function testReceiveInt()
    {
        var input = new BytesInput(Bytes.ofString(":13\r\n"));
        var proto = new RedisProtocol(input, null);
        assertEquals(13, proto.receiveInt());
    }

    public function testReceiveIntError()
    {
        var input = new BytesInput(Bytes.ofString("-ERROR\r\n"));
        var proto = new RedisProtocol(input, null);
        try
        {
            proto.receiveInt();
            assertTrue(false);
        }
        catch (e :RedisError)
        {
            assertTrue(true);
        }
    }
}
