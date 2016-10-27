part of discord;

/// A voice connection.
class VoiceConnection extends _BaseObj {
  int _ssrc;
  w_transport.WebSocket _socket;
  RawDatagramSocket _udpSocket;
  Map<String, dynamic> _voiceStateUpdate;
  Map<String, dynamic> _voiceServerUpdate;

  /// The voice channel the connection is for.
  VoiceChannel voiceChannel;

  VoiceConnection._new(Client client, this.voiceChannel) : super(client);

  Future<VoiceConnection> _connect(Map<String, dynamic> voiceStateUpdate,
      Map<String, dynamic> voiceServerUpdate) async {
    this._voiceStateUpdate = voiceStateUpdate;
    this._voiceServerUpdate = voiceServerUpdate;
    this._socket = await w_transport.WebSocket
        .connect(Uri.parse('ws://${voiceServerUpdate["d"]["endpoint"]}'));
    this._socket.listen(this._handleMsg);
    this._send("IDENTIFY", {
      "server_id": this.voiceChannel.guild.id,
      "user_id": this._client.user.id,
      "session_id": voiceStateUpdate['d']['session_id'],
      "token": voiceServerUpdate['d']['token']
    });
  }

  void _send(String op, dynamic d) {
    this._socket.add(JSON
        .encode(<String, dynamic>{"op": _Constants.voiceOpCodes[op], "d": d}));
  }

  void _heartbeat() {
    this._send("HEARTBEAT", null);
  }

  Future<Null> _handleMsg(String msg) async {
    dynamic json = JSON.decode(msg);
    print(json);
    switch (json['op']) {
      case _VoiceOPCodes.ready:
        Duration heartbeatInterval =
            new Duration(milliseconds: json['d']['heartbeat_interval']);
        new Timer.periodic(heartbeatInterval, (Timer t) => this._heartbeat());

        this._ssrc = json['d']['ssrc'];

        this._udpSocket = await RawDatagramSocket.bind(
            Uri.parse(this._voiceServerUpdate['d']['endpoint']).host,
            json['d']['port']);

        this._udpSocket.listen((RawSocketEvent e) {
          Datagram d = this._udpSocket.receive();
          this._udpSocket.send(d.data, d.address, d.port);
          if (d == null) return;

          String message = new String.fromCharCodes(d.data).trim();
          print(
              'Datagram from ${d.address.address}:${d.port}: ${message},${d.data}');
        });

        Int32List packet = new Int32List(70);
        packet.buffer.asByteData().setInt32(0, _ssrc);
        print(packet[0]);
        print(packet[1]);
        print(packet[2]);
        print(packet[3]);
        print(packet[4]);
        
        //packet[0] = _ssrc;
        this
            ._udpSocket
            .send(packet, this._udpSocket.address, this._udpSocket.port);
        break;
    }
  }
}
