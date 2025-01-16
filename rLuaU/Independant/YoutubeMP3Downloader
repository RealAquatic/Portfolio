
import sys, os
import pygame
from pytubefix import YouTube
from pytubefix.cli import on_progress
import subprocess
import OOPBase as Base

MainDirectory = r'{replace with directory}'

# Possible Uses

#Sounds = SoundManager(r"")   -- Put Base Directory Inside.
#Sounds.InputDirectory()
#Sounds.DownloadSound()
#Sounds.Load()
#Sounds.ListDirectory()
#Sounds.Play(input('\nEnter a Sound to play: '), True)
#Sounds.DeleteSound()


# Potentially Add Edit Directory



class SoundManager:
    def __init__(self, BaseDir):

        pygame.mixer.init() # Initialises mixer library
        
        self.Sounds = {}
        self.BaseDir = BaseDir or ""

    def Load(self):
        Items = os.listdir(self.BaseDir)
        for Item in Items: 
            self.Sounds[Item.split(".")[0]] = pygame.mixer.Sound(f"{self.BaseDir}/{Item}")

    def ListDirectory(self):
        Index = 0
        for Name, SoundObject in self.Sounds.items():
            print(f"{Index + 1}. {Name}")
            Index += 1

    def Play(self, SoundName, Repeat):
        if SoundName in self.Sounds:
            self.Sounds[SoundName].play()
        else:
            print(f"{SoundName} doesnt exist within {self.Sounds}\nPlease Enter a Valid Sound (By name)!")
            if Repeat:
                self.Play(input("\nTry again: "), Repeat)
                
    def InputDirectory(self, HasDir):
        Directory = self.BaseDir
        if Directory != "" and os.path.isdir(Directory):
            HasDir = True
            return True
        while HasDir != True:
            try:
                if Directory == "":
                    Directory2 = input("Enter a Directory: ")
                    if os.path.isdir(Directory2):
                        self.BaseDir = Directory2
                        HasDir = True
                    else:
                        print("Directory Doesn't Exist.")
                        continue
                break
            except:
                pass

    def DownloadSound(self):
        Directory = self.BaseDir
        Link = input("Enter the Youtube Link of the Video to download: ")
        YT = YouTube(Link, on_progress_callback = on_progress)
        Audio = YT.streams.get_audio_only()
        Audio.download(Directory)
        new_filename = input("\n\nEnter Filename: ")
        default_filename = Audio.default_filename
        subprocess.run([
            MainDirectory,
            '-i', os.path.join(Directory, default_filename),
            os.path.join(Directory, new_filename + ".mp3")
        ])
        os.remove(Directory + "\\" + default_filename)

    def DeleteSound(self):
        Directory = self.BaseDir
        SoundName = input("Enter Sound Name: ")
        if SoundName in self.Sounds:
            os.remove(Directory + "\\" + SoundName + ".mp3")
        else:
            print("Sound Could not be located within the directory!\n")


ValidOptionsYes = ['y','Y','Ye','Yes','Yea','Yeah','ye','yes','yeah','yup','Yup']
ValidOptionsNo = ['n','N','No','no','Nah','nah','Nope','nope']

Sounds = SoundManager(MainDirectory)

def Item1(*a):
    Sounds.InputDirectory(False)

def Item2(*a):
    Sounds.Load()
    while True:
        try:
            Choice = input("Do you wish to repeat if the sound doesn't exist in directory? (yes or no): ")
            if Choice in ValidOptionsYes:
                Choice = True
                break
            elif Choice in ValidOptionsNo:
                Choice = False
                break
            else:
                print("Invalid Option, Try Again.")
                continue
            break
        except:
            pass
        
    Sounds.ListDirectory()    
    Sounds.Play(input('\nEnter a Sound (by name) to play: '), Choice)

def Item3(*a):
    Sounds.DownloadSound()

def Item4(*a):
    Sounds.Load()
    Sounds.ListDirectory()
    Sounds.DeleteSound()

Select = Base.Selection({})

if True != Sounds.InputDirectory(False):
    Select.AddItem("Input Directory", Item1)
else:
    Select.AddItem("List Directory / Play Sound", Item2)
    Select.AddItem("Download Sound", Item3)
    Select.AddItem("Delete Sound", Item4)

while True:   
    Prompt = Select.Prompt(True)

    if Prompt != None:
        Prompt.Execute()
    else:
        print("Quitting.")
        break
