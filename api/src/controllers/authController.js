const AuthService = require('../services/AuthService');
const UserResource = require('../resources/UserResource');

class AuthController {
  async register(req, res) {
    try {
      const user = await AuthService.register(req.body);
      return res.status(201).json({
        success: true,
        message: 'Registrasi berhasil! Akun menunggu persetujuan Ketua RT.',
        data: UserResource.format(user)
      });
    } catch (error) {
      return res.status(400).json({ success: false, message: error.message });
    }
  }

  async login(req, res) {
    try {
      const { noHp, password } = req.body;
      const { user, token } = await AuthService.login(noHp, password);
      
      return res.status(200).json({
        success: true,
        message: 'Login berhasil',
        token: token,
        user: UserResource.format(user)
      });
    } catch (error) {
      return res.status(401).json({ success: false, message: error.message });
    }
  }
}

module.exports = new AuthController();