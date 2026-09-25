import DesignSystem
import SwiftUI

extension BookCover {
    init(book: Book, size: Size) {
        self.init(
            title: book.title, author: book.author, color: BookCover.generatedColor(for: book.title),
            image: book.cover.flatMap(UIImage.init(data:)).map(Image.init(uiImage:)), size: size,
            isFinished: book.isFinished, finishedValue: Text("Finished"))
    }
}
