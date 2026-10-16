"""A portable helper finds its model beside the executable."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
from voice import runtime_paths

class RuntimePaths(unittest.TestCase):
    def test_source_uses_the_project_model_folder(self):
        with patch.object(sys, 'frozen', False, create=True):
            self.assertEqual(runtime_paths.model_root(), Path(runtime_paths.__file__).resolve().parents[1] / '.tools/voice-models')

    def test_frozen_helper_uses_its_own_folder_without_a_working_directory(self):
        with patch.object(sys, 'frozen', True, create=True), patch.object(sys, 'executable', '/tmp/Test Game/voice/stuntcar-voice.exe'):
            self.assertEqual(runtime_paths.model_root(), Path('/tmp/Test Game/voice/models').resolve())
