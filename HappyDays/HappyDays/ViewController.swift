//
//  ViewController.swift
//  HappyDays
//
//  Created by Montserrat Gomez on 13/10/25.
//

import UIKit
import AVFoundation //microfono
import Photos
import Speech

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
	}

	@IBOutlet var helpLabel: UILabel!
	
	
	@IBAction func requestPermissions(_ sender: Any) {
		requestPhotoPermissions()
	}
	
	/// Funcion para solicitar permisos en cascada, permiso de galeria
	func requestPhotoPermissions() {
		PHPhotoLibrary.requestAuthorization { [ unowned self ] status in
			
			DispatchQueue.main.async {
				if status == .authorized {
					self.requestRecordPermission() //se solicita el otro permiso
				} else {
					self.helpLabel.text = "No tienes acceso a la biblioteca de fotos"
				}
			}
		}
	}
	
	/// Funcion para solicitar permiso al microfono
	func requestRecordPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.requestTranscribePermissions()
                    } else {
                        self.helpLabel.text = "Permiso no concedido"
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.requestTranscribePermissions()
                    } else {
                        self.helpLabel.text = "Permiso no concedido"
                    }
                }
            }
        }
	}
	
	/// Funcion para solicitar permiso de lectura de voz
	func requestTranscribePermissions() {
		SFSpeechRecognizer.requestAuthorization { status in
			DispatchQueue.main.async {
				if status == .authorized {
					self.authorizationComplete()
				} else {
					self.helpLabel.text = "No tienes acceso a la microfón"
				}
			}
		}
	}
	
	func authorizationComplete(){
		dismiss(animated: true)
	}
	
	
}

