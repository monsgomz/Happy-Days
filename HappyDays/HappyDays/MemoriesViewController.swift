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


class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout //The methods of this protocol define the size of items and the spacing between items in the grid.
{
	
	var memories : [URL] = []
	
	override func viewDidAppear(_ animated: Bool) {
		checkPermissions()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadMemories()
		//como ToolBarItem en SwiftUI
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))

    }

	
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
	
	@objc func addTapped() {
		let picker = UIImagePickerController()
		picker.modalPresentationStyle = .formSheet
		picker.delegate = self
		navigationController?.present(picker, animated: true)
	}
	
	
	/// Funcion para manejar la respuesta del modal
	/// - Parameters:
	///   - picker:
	///   - info:
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
		dismiss(animated: true)
		
		if let possibleImage = info[.originalImage] as? UIImage {
			saveNewMemory(image: possibleImage)
			loadMemories()
		}
		
	}
	
	func saveNewMemory(image: UIImage) {
		//crear un nombre
		let memoryName = "memory-(Date().timeIntervaalSince1970)"
		//nombres para las imagenes y thumbnail
		let imageName = memoryName + ".jpg"
		let thumbnaailName = memoryName + ".thumb"
		
		do {
			//Creamos una url para convertir a jpeg
			let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
			
			//Convertimos
			if let jpegData = image.jpegData(compressionQuality: 0.8)
			{
				try jpegData.write(to: imagePath, options: [.atomicWrite])
			}
			
			//Creamos el thumbnail
			if let thumbnail = resize(image: image, to: 200) {
				let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnaailName)
				if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
					try jpegData.write(to: imagePath, options: [.atomicWrite])
				}
			}
				
			
		}
		catch {
			print("🧡 Failed to save to disk")
		}
		
	}
	
	func resize(image: UIImage, to width: CGFloat) -> UIImage? {
		//Se calcula el tamaño
		let scale = width / image.size.width
		let height = image.size.height * scale
		
		//Para crear o dibujar imagenes en memoria
		UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
		
		image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()!
		//Se termina de dibujar
		UIGraphicsEndImageContext()
		
		return newImage
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		if section == 0 { //por el header que es section 0
			return 0
		} else {
			return memories.count
		}
	}
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	//Con estas funciones nunca es nil la url
	func imageURL(for memory: URL) -> URL? {
		return memory.appendingPathExtension("jpg")
	}
	
	func thumbnailURL(for memory: URL) -> URL? {
		return memory.appendingPathExtension("thumb")
	}
	
	func audioURL(for memory: URL) -> URL? {
		return memory.appendingPathExtension("m4a")
	}
	
	func transcriptionURL(for memory: URL) -> URL? {
		return memory.appendingPathExtension("txt")
	}
	
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
		
		let memory = memories[indexPath.row]
		let imageName = (thumbnailURL(for: memory)?.path)!
		let image = UIImage(contentsOfFile: imageName)
		cell.imageView.image = image
		
		return cell
	}
	
	//Une el header con el archivo con identificador Header
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		
		return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referencesSizeForHeadersInSection section: Int) -> CGSize {
		if section == 0 { //cuando la seccion no necesita header, se pone 0
			
			return .zero
		} else {
			return CGSize(width: 0, height: 50)
		}
	}
}
