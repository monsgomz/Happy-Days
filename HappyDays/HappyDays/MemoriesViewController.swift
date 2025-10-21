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
import CoreSpotlight
import UniformTypeIdentifiers


class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
							  AVAudioRecorderDelegate, UICollectionViewDelegateFlowLayout //The methods of this protocol define the size of items and the spacing between items in the grid.
{
	
	var memories : [URL] = []
	var activeMemory: URL!
	var audioRecorder : AVAudioRecorder?
	var recordingURL: URL!
	var audioPlayer: AVAudioPlayer?
	
	override func viewDidAppear(_ animated: Bool) {
		checkPermissions()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
		
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
			if filename.hasSuffix(".thumb") { //terminen con .thumb
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
	
	/// Funcion que guarda la imagen en disco
	/// - Parameter image: Imagen
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
	
	/// Funcion para crear thumbnail
	/// - Parameters:
	///   - image: imagen
	///   - width: tamaño
	/// - Returns: imagen
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
	
	/// Funcion cuando se hace gesto en celda
	@objc func memoryLongPress(sender: UILongPressGestureRecognizer){
		
		if sender.state == .began {
			let cell = sender.view as! MemoryCell
			
			if let indexPath = collectionView.indexPath(for: cell) {
				activeMemory = memories[indexPath.row]
				recordMemory()
			}
			
		}
		else if sender.state == .ended {
			finishRecording(success: true)
		}

	}
	
	/// Funcion para Grabar audio
	func recordMemory() {
		collectionView.backgroundColor = .red
		audioPlayer?.stop()
		
		let recordingSession = AVAudioSession.sharedInstance()
		do {
			try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
			try recordingSession.setActive(true)
			
			let settings = [
				AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
				AVSampleRateKey: 44100,
				AVNumberOfChannelsKey: 2,
				AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
			]
			
			audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
			audioRecorder?.delegate = self
			audioRecorder?.record()
			
		} catch {
			print("Failed to set up audio session: \(error)")
			finishRecording(success: false)
		}
	}
	
	/// Funcion para terminar de grabar
	func finishRecording(success: Bool) {
		collectionView.backgroundColor = .black
		
		audioRecorder?.stop()
		
		if success {
			do {
				let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
				let fm = FileManager.default
				
				if fm.fileExists(atPath: memoryAudioURL.path()) {
					try fm.removeItem(at: memoryAudioURL)
				}
				
				try fm.moveItem(at: recordingURL, to: memoryAudioURL)
				transcribeAudio(memory: activeMemory)
				
			} catch let error {
				print("Error al grabar \(error)")
			}
		}
		
	}
	
	/// Funcion para transcribir el audio
	/// - Parameter memory: archivo de audio
	func transcribeAudio(memory: URL) {
		let audio = audioURL(for: memory)
		let transcription = transcriptionURL(for: memory)
		let recognizer = SFSpeechRecognizer()
		let request = SFSpeechURLRecognitionRequest(url: audio!) //reconocedor de voz
		
		recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
			
			guard let result = result else {
				print("Error")
				return
			}
			
			if result.isFinal {
				let text = result.bestTranscription.formattedString
				
				do {
					try text.write(to: transcription!, atomically: true, encoding: String.Encoding.utf8)
					self.indexMemory(memory: memory, text: text)
				} catch {
					print("Fallo la transcripcion")
				}
			}
			
		}
	}
	
	func indexMemory(memory: URL, text: String) {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
		attributeSet.title = "Happy Days Memory"
		attributeSet.contentDescription = text
		attributeSet.thumbnailURL = thumbnailURL(for: memory)
		
		let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "justmonz.com", attributeSet: attributeSet)
		
		CSSearchableIndex.default().indexSearchableItems([item])
		{
			error in
			if let error = error {
				print("Indexing error")
			} else {
				print("Busqueda correcta")
			}
		}
	}
	
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
		
		let memory = memories[indexPath.row]
		let imageName = (thumbnailURL(for: memory)?.path)!
		let image = UIImage(contentsOfFile: imageName)
		cell.imageView.image = image
		
		if cell.gestureRecognizers == nil {
			let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
			recognizer.minimumPressDuration = 0.25
			cell.addGestureRecognizer(recognizer)
			
			cell.layer.borderColor = UIColor.white.cgColor
			cell.layer.borderWidth = 3
			cell.layer.cornerRadius = 10
			
		}
		
		return cell
	}
	
	//Une el header con el archivo con identificador Header
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		
		return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		if section == 0 { //cuando la seccion no necesita header, se pone 0
			
			return .zero
		} else {
			return CGSize(width: 0, height: 50)
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let memory = memories[indexPath.row]
		let fm = FileManager.default
		
		do {
			let audioName = audioURL(for: memory)
			let transcriptionName = transcriptionURL(for: memory)
			
			if fm.fileExists(atPath: audioName!.path) {
				audioPlayer = try AVAudioPlayer(contentsOf: audioName!)
				audioPlayer?.play()
			}
			
			if fm.fileExists(atPath: transcriptionName!.path) {
				let contents = try String(contentsOf: transcriptionName!)
				print(contents)
			}
				
		} catch {
			print("Error")
		}
		
	}
}

