from app import db
import os
from pathlib import Path
from flask import url_for
import app.funcs as funcs
from flask import current_app
from datetime import datetime


class File():
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String)
    path = db.Column(db.String(2048))

    def save_locally(self, file_format):
        folder = Path(current_app.root_path, self.path)
        self.filename = f"{datetime.now().strftime('%Y,%m,%d,%H,%M,%S')}.{file_format}"
        full_local_path = Path(current_app.root_path, folder, self.filename)
        # make sure the whole path exists
        Path(folder).mkdir(parents=True, exist_ok=True)
        return full_local_path

    def upload_to_bucket(self):
        # Uploading to bucket
        print("#"*10)
        print(self.filename)
        print(str(Path(self.path, self.filename)))
        print("#"*10)

        funcs.upload_file(file_path=self.full_local_path, object_name=str(Path(self.path, self.filename)))

    @property
    def full_local_path(self):
        folder = Path(current_app.root_path, self.path)
        full_local_path = Path(current_app.root_path, folder, self.filename)
        return str(full_local_path)

    @property
    def full_bucket_path(self):
        return str(Path(self.path, self.filename))

    @property
    def src(self):
        if self.is_local:
            url = url_for("static", filename=funcs.join_parts(*Path(self.path).parts[1:], self.filename))
            return url
        else:
            #generate url for image
            return funcs.generate_presigned_url(self.full_bucket_path)

    def empty(self):
        if not self.is_empty:
            funcs.silent_local_remove(self.full_local_path)
            funcs.delete_file(self.full_bucket_path)

    def remove(self):
        self.empty()
        db.session.delete(self)

    @property
    def is_local(self):
        local_folder = Path(current_app.root_path, self.path)
        return local_folder.exists() and any(local_folder.iterdir())

    @property
    def is_global(self):
        exists = bool(funcs.list_files(folder_path=self.path))
        return exists

    @property
    def is_empty(self):
        return not self.is_local

    def make_local(self):
        folder = Path(current_app.root_path, self.path)
        folder.mkdir(parents=True, exist_ok=True)
        funcs.download_file(self.full_bucket_path, self.full_local_path)

    def __repr__(self):
        return "<File {}>".format(Path(self.path,self.filename))
