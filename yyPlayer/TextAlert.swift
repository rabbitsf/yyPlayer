import SwiftUI

struct TextAlert: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var text: String
    var title: String
    var message: String?
    var placeholder: String
    var onComplete: (String?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // An empty view controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = placeholder
                textField.text = text
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                isPresented = false
                onComplete(nil)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                isPresented = false
                text = alert.textFields?.first?.text ?? ""
                onComplete(text)
            })
            DispatchQueue.main.async {
                uiViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension View {
    func textAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        placeholder: String = "",
        text: Binding<String>,
        onComplete: @escaping (String?) -> Void
    ) -> some View {
        self.background(
            TextAlert(isPresented: isPresented, text: text, title: title, message: message, placeholder: placeholder, onComplete: onComplete)
                .opacity(0) // Invisible until triggered
        )
    }
}

