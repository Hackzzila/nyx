part of discord;

/// A guild channel.
class VoiceChannel extends GuildChannel {
  /// The channel's bitrate.
  int bitrate;

  /// The channel's user limit.
  int userLimit;

  VoiceChannel._new(Client client, Map<String, dynamic> data, Guild guild)
      : super._new(client, data, guild, "voice") {
    this.bitrate = data['bitrate'];
    this.userLimit = data['user_limit'];
  }

  /// Edits the channel.
  Future<VoiceChannel> edit(
      {String name: null,
      int bitrate: null,
      int position: null,
      int userLimit: null}) async {
    w_transport.Response r =
        await this._client._http.send('PATCH', "/channels/${this.id}", body: {
      "name": name != null ? name : this.name,
      "bitrate": bitrate != null ? bitrate : this.bitrate,
      "user_limit": userLimit != null ? userLimit : this.userLimit,
      "position": position != null ? position : this.position
    });
    return new VoiceChannel._new(
        this._client, r.body.asJson() as Map<String, dynamic>, this.guild);
  }

  /// Joins the voice channel.
  Future<Null> join({mute: false, deaf: false}) async {
    this.guild.shard._send("VOICE_STATE_UPDATE", {
      "guild_id": this.guild.id,
      "channel_id": this.id,
      "self_mute": mute,
      "self_deaf": deaf
    });

    dynamic msg1 = await this
        .guild
        .shard
        ._onMsg
        .stream
        .firstWhere((Map<String, dynamic> msg) {
      if ((msg['t'] == "VOICE_STATE_UPDATE" &&
              msg['d']['session_id'] == this.guild.shard._sessionId) ||
          (msg['t'] == "VOICE_SERVER_UPDATE" &&
              msg['d']['guild_id'] == this.guild.id))
        return true;
      else
        return false;
    });

    dynamic msg2 = await this
        .guild
        .shard
        ._onMsg
        .stream
        .firstWhere((Map<String, dynamic> msg) {
      if ((msg['t'] == "VOICE_STATE_UPDATE" &&
              msg['d']['session_id'] == this.guild.shard._sessionId) ||
          (msg['t'] == "VOICE_SERVER_UPDATE" &&
              msg['d']['guild_id'] == this.guild.id))
        return true;
      else
        return false;
    });

    Map<String, dynamic> voiceStateUpdate = msg1['t'] == "VOICE_STATE_UPDATE"
        ? msg1 as Map<String, dynamic>
        : msg2 as Map<String, dynamic>;

    Map<String, dynamic> voiceServerUpdate = msg1['t'] == "VOICE_SERVER_UPDATE"
        ? msg1 as Map<String, dynamic>
        : msg2 as Map<String, dynamic>;

    new VoiceConnection._new(this._client, this)
        ._connect(voiceStateUpdate, voiceServerUpdate);
  }
}
