defmodule CsProtoParser do
  @doc """
  Parses a C# file content and extracts BasePacket/EncryptPacket descendants and their ProtoMember fields.
  Returns a map with class information including encryption status and proto members.
  """
  def parse(content) do
    # Match both BasePacket and EncryptPacket classes
    class_patterns = [
      {~r/\[ProtoContract\]\s*public class (\w+)\s*:\s*BasePacket[^{]*{([^}]+)}/, false},
      {~r/\[ProtoContract\]\s*public class (\w+)\s*:\s*EncryptPacket[^{]*{([^}]+)}/, true},
      # Simpler pattern for classes without body
      {~r/public class (\w+)\s*:\s*BasePacket[^{]*$/, false},
      {~r/public class (\w+)\s*:\s*EncryptPacket[^{]*$/, true}
    ]

    class_patterns
    |> Enum.flat_map(fn {pattern, is_encrypted} ->
      Regex.scan(pattern, content)
      |> Enum.map(fn 
        # For matches with class body
        [_, class_name, class_body] -> 
          proto_members = extract_proto_members(class_body)
          {class_name, %{
            encrypted: is_encrypted,
            proto_members: proto_members
          }}
        # For matches without class body
        [_, class_name] -> 
          {class_name, %{
            encrypted: is_encrypted,
            proto_members: []
          }}
      end)
    end)
    |> Enum.into(%{})
  end

  @doc """
  Extracts ProtoMember fields from a class body.
  Returns a list of tuples containing {field_name, proto_member_number, field_type}.
  """
  def extract_proto_members(class_body) do
    proto_member_regex = ~r/\[ProtoMember\((\d+)\)\]\s*public\s+([^\s]+)\s+(\w+)\s*;/
    
    Regex.scan(proto_member_regex, class_body || "")
    |> Enum.map(fn [_, number, type, field_name] ->
      {field_name, String.to_integer(number), type}
    end)
  end

  def test() do
    # Example usage:
    content = """
    [ProtoContract]
    public class SC_PingToGateWay : BasePacket // TypeDefIndex: 1094
    {
        // Fields
        [ProtoMember(1)]
        public DateTime sendTime; // 0x18
        public DateTime recvTime; // 0x20
        [ProtoMember(2)]
        public DateTime serverUtcNow; // 0x28

        // Properties
        public override ePacketId packetType { get; }

        // Methods
        public override ePacketId get_packetType() { }
        public void .ctor() { }
    }
    """

    # Parse and print results
    result = CsProtoParser.parse(content)
    IO.inspect(result, label: "Parsed Proto Classes")
  end
end
