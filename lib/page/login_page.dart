import 'package:face_auth_flutter/page/face_recognition/camera_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //

  double match = 0.0;

  @override
  void initState() {
    // dp("User = ", LocalDB.getUser().name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Face Authentication"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Match percentage = $match",
                  style: const TextStyle(fontSize: 20, color: Colors.amber),
                ),
                Text(
                  match == 0.0
                      ? ""
                      : match < 0.99
                          ? "Success"
                          : "Fail",
                  style: TextStyle(
                      color: match < 0.99 ? Colors.green : Colors.red,
                      fontSize: 20),
                ),
                buildButton(
                  text: 'Scan Document',
                  icon: Icons.app_registration_rounded,
                  onClicked: () async {
                    showAboutDialog(context: context, children: [
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceScanScreen(
                                        cameraType: CameraType.front,
                                        scanType: ScanType.register,
                                      ))).then(
                            (value) {
                              match = value;
                              setState(() {});
                            },
                          );
                        },
                        child: const Text("Front Camera"),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceScanScreen(
                                        cameraType: CameraType.back,
                                        scanType: ScanType.register,
                                      ))).then(
                            (value) {
                              match = value;
                              setState(() {});
                            },
                          );
                        },
                        child: const Text("Back Camera"),
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 24),
                buildButton(
                  text: 'Compare',
                  icon: Icons.login,
                  onClicked: () async {
                    showAboutDialog(context: context, children: [
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceScanScreen(
                                        cameraType: CameraType.front,
                                        scanType: ScanType.authenticate,
                                      ))).then(
                            (value) {
                              match = value;
                              setState(() {});
                            },
                          );
                        },
                        child: const Text("Front Camera"),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FaceScanScreen(
                                        cameraType: CameraType.back,
                                        scanType: ScanType.authenticate,
                                      ))).then(
                            (value) {
                              match = value;
                              setState(() {});
                            },
                          );
                        },
                        child: const Text("Back Camera"),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onClicked,
  }) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          style: const TextStyle(fontSize: 20),
        ),
        onPressed: onClicked,
      );
}
