from pytubefix import YouTube, Playlist
import os
import sys
import time

def estimate_time(stream, speed_mbps=0.5):
    filesize = stream.filesize / (1024 * 1024)
    return filesize / speed_mbps

class Options:
    def __init__(self):
        self.type = None
        self.url = None
        self.dir = "."

        while True:
            print("\nSelect option:")
            print("1. Choose download type")
            print("2. Download")
            print("3. Exit")
            choice = input("> ")

            while not (choice.isdigit() and 1 <= int(choice) <= 3):
                print("Invalid choice. Enter 1–3.")
                choice = input("> ")

            if choice == "1":
                self.type = self.select_type()
                print(f"Selected type: {self.type}")

            elif choice == "2":
                if not self.type:
                    print("❌ No download type selected.")
                    continue

                if "playlist" in self.type:
                    self.url = input("Enter playlist URL: ")
                else:
                    self.url = input("Enter video URL: ")

                self.dir = input("Enter download directory (default = current): ") or "."

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

        return types.get(choice, "video")

    def start_download(self):
        if "playlist" in self.type:
            PlaylistDownloader(self.url, self.dir, self.type)
        else:
            verifier = VideoVerifier(self.url, self.dir)
            if verifier.yt:
                VideoDownloader(verifier.yt, verifier.dir, self.type)

class VideoVerifier:
    def __init__(self, url, dir):
        self.yt = self.verify_url(url)
        self.dir = self.verify_dir(dir)

    def verify_url(self, url):
        try:
            yt = YouTube(url)
            print(f"Found Video: `{yt.title}` by `{yt.author}`")
            return yt
        except Exception as e:
            print(f"Error verifying URL: {e}")
            return None

    def verify_dir(self, dir):
        if not os.path.exists(dir):
            print(f"Directory `{dir}` not found. Using current directory.")
            return "."
        return dir

class VideoDownloader:
    def __init__(self, yt, dir, download_type):
        self.yt = yt
        self.dir = dir
        self.type = download_type
        self.download()

    def download(self):
        try:
            if self.type == "video":
                stream = self.yt.streams.get_highest_resolution()

            elif self.type == "audio":
                stream = self.yt.streams.filter(only_audio=True).order_by("abr").desc().first()

            est = estimate_time(stream)
            print(f"Estimated download time: {est:.1f} seconds")

            out_file = stream.download(output_path=self.dir)

            if self.type == "audio":
                base, ext = os.path.splitext(out_file)
                new_file = base + ".mp3"
                os.rename(out_file, new_file)

            print("Download complete!")

        except Exception as e:
            print(f"Download error: {e}")

class PlaylistDownloader:
    def __init__(self, url, dir, download_type):
        self.url = url
        self.dir = dir
        self.type = download_type
        self.download_playlist()

    def download_playlist(self):
        try:
            playlist = Playlist(self.url)
            print(f"\n📃 Playlist: {playlist.title}")
            print(f"Videos found: {len(playlist.video_urls)}\n")

            total_est_time = 0

            print("Calculating estimated total download time...")
            for video_url in playlist.video_urls:
                yt = YouTube(video_url)

                if self.type == "playlist_video":
                    stream = yt.streams.get_highest_resolution()
                else:
                    stream = yt.streams.filter(only_audio=True).order_by("abr").desc().first()

                total_est_time += estimate_time(stream)

            print(f"Estimated total time: {total_est_time:.1f} seconds\n")

            for index, video_url in enumerate(playlist.video_urls, start=1):
                yt = YouTube(video_url)
                print(f"Downloading {index}/{len(playlist.video_urls)}: {yt.title}")

                if self.type == "playlist_video":
                    stream = yt.streams.get_highest_resolution()
                    stream.download(output_path=self.dir)

                elif self.type == "playlist_audio":
                    stream = yt.streams.filter(only_audio=True).order_by("abr").desc().first()
                    out_file = stream.download(output_path=self.dir)
                    base, ext = os.path.splitext(out_file)
                    os.rename(out_file, base + ".mp3")

            print("\n✅ Playlist download complete!")

        except Exception as e:
            print(f"Playlist error: {e}")

if __name__ == "__main__":
    Options()