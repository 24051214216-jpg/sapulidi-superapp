class UserResource {
  static format(user) {
    if (!user) return null;
    return {
      id: user.id,
      nama: user.nama,
      nik: user.nik,
      noHp: user.noHp,
      role: user.role,
      status: user.status,
      blokRumah: user.blokRumah,
      noRumah: user.noRumah,
      rt: user.rt,
      rw: user.rw
    };
  }

  static collection(users) {
    return users.map(this.format);
  }
}

module.exports = UserResource;