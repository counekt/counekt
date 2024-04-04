from app import db
from app.models.base import Base
from app.models.static.file import File
from PIL import Image


class Photo(File):

    __tablename__ = "file"

    def save(self, file, d=(256, 256), path=None):
        image = Image.open(file)
        new_image = image.resize((256, 256), Image.ANTIALIAS)
        new_image.format = image.format
        full_local_path = self.save_locally(file_format=image.format)
        print(full_local_path)
        new_image.save(full_local_path)
        self.upload_to_bucket()
        self.is_empty = False

    def empty(self):
        super(Photo, self).empty()
        self.is_empty = True

    def show(self):
        # For display in shell
        image = Image.open(self.full_path)
        image.show()

    @property
    def src(self):
        if not self.is_empty:
            return super(Photo, self).src
        return self.replacement

    def __repr__(self):
        return "<Photo {}>".format(self.filename or self.replacement)
