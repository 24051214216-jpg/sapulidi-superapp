const prisma = require('../config/prisma');

class UserRepository {
  async findByNoHp(noHp) {
    return await prisma.user.findUnique({ where: { noHp } });
  }

  async findByNik(nik) {
    return await prisma.user.findUnique({ where: { nik } });
  }

  async createUser(data) {
    return await prisma.user.create({ data });
  }
}

module.exports = new UserRepository();