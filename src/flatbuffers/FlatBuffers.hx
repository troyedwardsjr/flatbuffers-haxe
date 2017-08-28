package flatbuffers;

/*
#if js
typedef FlatBuffers = flatbuffers.impl.FlatBuffersJs; 
#elseif cpp
typedef FlatBuffers = flatbuffers.impl.FlatBuffersCpp; 
typedef Builder = flatbuffers.impl.FlatBuffersCpp.BuilderCpp;
#end
*/
typedef FlatBuffers = flatbuffers.impl.FlatBuffersPure; 
typedef Builder = flatbuffers.impl.FlatBuffersPure.Builder;
typedef ByteBuffer = flatbuffers.impl.FlatBuffersPure.ByteBuffer;
typedef Offset = flatbuffers.impl.FlatBuffersPure.Offset;
typedef Long = flatbuffers.impl.FlatBuffersPure.Long;