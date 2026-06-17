import os
import sys
import traceback
from yt_dlp import YoutubeDL
from urllib.parse import urlparse, parse_qs


class Options:

    def __init__(self):
        self.type = None
        self.url = None
        self.dir = "."
        self.playlist_start = 1

        while True:

            print("\nSelect option:")
            print("1. Choose download type")
            print("2. Download")
            print("3. Exit")

            choice = input("> ")

            while not (choice.isdigit() and 1 <= int(choice) <= 3):
                print("Invalid choice. Enter 1-3.")
                choice = input("> ")


            if choice == "1":

                self.type = self.select_type()

                print(
                    f"Selected type: {self.type}"
                )


            elif choice == "2":

                if not self.type:
                    print(
                        "❌ No download type selected."
                    )
                    continue


                self.url = input(
                    "Enter URL: "
                )


                if "playlist" in self.type:

                    start = input(
                        "Start from playlist position (default 1): "
                    )

                    if start.isdigit():
                        self.playlist_start = int(start)
                    else:
                        self.playlist_start = 1


                self.dir = (
                    input(
                        "Enter download directory "
                        "(default=current): "
                    )
                    or "."
                )


                self.start_download()



            elif choice == "3":

                print("Exiting...")
                sys.exit()



    def select_type(self):

        print("\nSelect download type:")
        print("1. Video (MP4)")
        print("2. Audio (MP3)")
        print("3. Playlist Video (MP4)")
        print("4. Playlist Audio (MP3)")

        choice = input("> ")


        types = {

            "1": "video",
            "2": "audio",
            "3": "playlist_video",
            "4": "playlist_audio"

        }


        return types.get(
            choice,
            "video"
        )



    def start_download(self):

        Downloader(
            self.url,
            self.dir,
            self.type,
            self.playlist_start
        )





class Downloader:


    def __init__(
        self,
        url,
        directory,
        download_type,
        playlist_start=1
    ):

        self.url = self.clean_url(url)
        self.dir = directory
        self.type = download_type
        self.playlist_start = playlist_start

        self.download()



    def clean_url(self, url):

        # Convert YouTube Music URLs
        # into normal YouTube URLs

        if "music.youtube.com" in url:

            parsed = urlparse(url)

            params = parse_qs(
                parsed.query
            )

            if "list" in params:

                return (
                    "https://www.youtube.com/playlist?list="
                    + params["list"][0]
                )

            if "v" in params:

                return (
                    "https://www.youtube.com/watch?v="
                    + params["v"][0]
                )

        return url



    def download(self):

        try:

            if not os.path.exists(self.dir):

                print(
                    "Directory not found. Using current."
                )

                self.dir = "."


            print(
                "\nSaving to:"
            )

            print(
                os.path.abspath(self.dir)
            )


            options = {

                "outtmpl":
                    os.path.join(
                        self.dir,
                        "%(title)s.%(ext)s"
                    ),


                "quiet": False,


                "ignoreerrors": False,


                # Resume support
                "download_archive":
                    os.path.join(
                        self.dir,
                        "downloaded.txt"
                    ),

                "extractor_args":
                    {
                        "youtube":
                            {
                                "player_client":
                                    [
                                        "android",
                                        "web"
                                    ]
                            }
                    }

            }



            if (
                self.type == "video"
                or
                self.type == "playlist_video"
            ):

                options.update({

                    # More compatible than bestvideo+bestaudio
                    "format":
                        "best",


                    "playliststart":
                        self.playlist_start,


                    "playlistend":
                        100

                })



            elif (
                self.type == "audio"
                or
                self.type == "playlist_audio"
            ):

                options.update({

                    "format":
                        "bestaudio/best",


                    "playliststart":
                        self.playlist_start,


                    "playlistend":
                        100,


                    "postprocessors":
                    [
                        {
                            "key":
                                "FFmpegExtractAudio",

                            "preferredcodec":
                                "mp3",

                            "preferredquality":
                                "192"
                        }
                    ]

                })



            print(
                "\nStarting download...\n"
            )


            with YoutubeDL(options) as ydl:

                ydl.download(
                    [
                        self.url
                    ]
                )


            print(
                "\n✅ Download complete!"
            )


        except Exception:
            traceback.print_exc()





if __name__ == "__main__":

    Options()
