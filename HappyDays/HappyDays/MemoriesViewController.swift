//
//  MemoriesViewController.swift
//  HappyDays
//
//  Created by Montserrat Gomez on 13/10/25.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesViewController: UICollectionViewController {
	
	var memories : [URL] = []
	
	override func viewDidAppear(_ animated: Bool) {
		checkPermissions()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadMemories()

    }
    
	@IBOutlet var imageView: UIImageView!
	
	func checkPermissions() {
		//revisamos los permisos de todos
		let photoAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
		let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
		let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
		
		let authorized = photoAuthorized && recordingAuthorized && speechAuthorized
			
		if authorized == false { //si no se solicitan, presentando la otra view
			if let vc =
				storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
				navigationController?.present(vc, animated: true)
			}
		}
	}
	
	/// Funcion para acceder a documentos
	/// - Returns: url
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		return documentsDirectory
	}
	
	/// Funcion para obtener las imagenes
	func loadMemories() {
		memories.removeAll()
		
		//attempt to load all the memories in our documents directory
		guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
			return
		}
		
		for file in files { //se revisa que no sea .thumb para solo contar 1 vez
			let filename = file.lastPathComponent
			if filename.hasPrefix(".thumb") {
				let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
				
				//crea la ruta completa
				let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
				
				memories.append(memoryPath)
				
				//recargar la coleccion, seccion 1 porque la 0 es el search bar
				collectionView.reloadSections(IndexSet(integer: 1))
				
				
			}
			
		}
	}

}
