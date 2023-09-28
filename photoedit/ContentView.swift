//
//  ContentView.swift
//  photoedit
//
//  Created by Jigar on 27/09/23.
//


import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

struct ContentView: View {
  @State private var selectedImage: UIImage?
  @State private var editedImage: UIImage?
  @State private var isImagePickerPresented = false
  @State private var isEditing = false
  @State private var filterIntensity = 0.5

  // Filters
  let sepiaFilter = CIFilter.sepiaTone()
  let blackAndWhiteFilter = CIFilter.colorMonochrome()
  let blurFilter = CIFilter.gaussianBlur()
  let contrastFilter = CIFilter.colorControls()

  var body: some View {
    NavigationView {
      VStack {
        Button("Open Photo") {
          isImagePickerPresented = true
        }
        .sheet(isPresented: $isImagePickerPresented) {
          ImagePicker(selectedImage: $selectedImage, isImagePickerPresented: $isImagePickerPresented)
        }

        if let image = editedImage ?? selectedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

          HStack {
            Button("Sepia") {
              applySepiaFilter()
            }

            Button("Black & White") {
              applyBlackAndWhiteFilter()
            }

            Button("Blur") {
              applyBlurFilter()
            }

            Button("Contrast") {
              applyContrastFilter()
            }
             
            Button("Reset") {
              resetEditing()
            }
          }
          .padding()

          Slider(value: $filterIntensity, in: 0...1, step: 0.01)
            .padding()

          Button("Apply Effects") {
            applyFilters()
          }
          .padding()

          Spacer()

          Button("Save to Photos") {
            isEditing = true
          }
          .padding()
        }
      }
      .navigationBarTitle("Photo Editor")
      .fullScreenCover(isPresented: $isEditing) {
        if let editedImage = editedImage {
          PhotoSaver(editedImage: editedImage)
        }
      }
    }
  }

  func applySepiaFilter() {
    guard let inputImage = selectedImage else { return }
    let ciImage = CIImage(image: inputImage)
    sepiaFilter.inputImage = ciImage
    sepiaFilter.intensity = Float(filterIntensity)
    if let outputCIImage = sepiaFilter.outputImage {
      editedImage = UIImage(ciImage: outputCIImage)
    }
  }

  func applyBlackAndWhiteFilter() {
    guard let inputImage = selectedImage else { return }
    let ciImage = CIImage(image: inputImage)
    blackAndWhiteFilter.inputImage = ciImage
    if let outputCIImage = blackAndWhiteFilter.outputImage {
      editedImage = UIImage(ciImage: outputCIImage)
    }
  }

  func applyBlurFilter() {
    guard let inputImage = selectedImage else { return }
    let ciImage = CIImage(image: inputImage)
    blurFilter.inputImage = ciImage
    blurFilter.radius = filterIntensity <= 0.5 ? Float(filterIntensity) * 30 : Float(filterIntensity) * 50
    if let outputCIImage = blurFilter.outputImage {
      editedImage = UIImage(ciImage: outputCIImage)
    }
  }

  func applyContrastFilter() {
    guard let inputImage = selectedImage else { return }
    let ciImage = CIImage(image: inputImage)
    contrastFilter.inputImage = ciImage
    contrastFilter.contrast = Float(filterIntensity) * 2
    if let outputCIImage = contrastFilter.outputImage {
      editedImage = UIImage(ciImage: outputCIImage)
    }
  }

  func resetEditing() {
    editedImage = nil
    filterIntensity = 0.5
  }

  func applyFilters() {
    // Apply the filters in the order that you want them to be applied.
    applySepiaFilter()
    applyBlackAndWhiteFilter()
    applyBlurFilter()
    applyContrastFilter()

    // Do not save the edited image here; it should be saved after editing in PhotoSaver.
  }
}

struct ImagePicker: View {
  @Binding var selectedImage: UIImage?
  @Binding var isImagePickerPresented: Bool

  var body: some View {
    ImagePickerRepresentable(selectedImage: $selectedImage, isPresented: $isImagePickerPresented)
  }
}

struct ImagePickerRepresentable: UIViewControllerRepresentable {
  @Binding var selectedImage: UIImage?
  @Binding var isPresented: Bool

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: ImagePickerRepresentable

    init(parent: ImagePickerRepresentable) {
      self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.originalImage] as? UIImage {
        parent.selectedImage = image
      }
      parent.isPresented = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.isPresented = false
    }
  }
}

struct PhotoSaver: View {
  var editedImage: UIImage

  var body: some View {
    VStack {
      Image(uiImage: editedImage)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()

      Button("Save to Photos") {
        saveToPhotos()
      }
      .padding()
    }
    .navigationBarTitle("Save Photo")
  }

  func saveToPhotos() {
    if let data = editedImage.jpegData(compressionQuality: 0.8) {
      PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: data, options: nil)
      } completionHandler: { success, error in
        if success {
          // Photo saved successfully
        } else if let error = error {
          // Handle the error
          print("Error saving photo: \(error.localizedDescription)")
        }
      }
    }
  }
}
