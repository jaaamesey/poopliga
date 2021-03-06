using Godot;
using System;
using System.Windows.Forms;


public class FileDialog : Node
{
    [STAThread]
    public static string OpenFileDialog()
    {
        var openFileDialog = new OpenFileDialog
        {
            InitialDirectory = "",
            Filter = "Poopliga files (*.poopliga, *.ppga, *.json)|*.poopliga;*.ppga;*.json|All files (*.*)|*.*",
            FilterIndex = 1,
            RestoreDirectory = true
        };

        var result = openFileDialog.ShowDialog();
        if (result == DialogResult.OK)
        {
            var path = openFileDialog.FileName;
            return path;
        }

        return null;
    }

    [STAThread]
    public static string SaveFileDialog()
    {
        var saveFileDialog = new SaveFileDialog
        {
            InitialDirectory = "",
            Filter = "Poopliga files (*.poopliga, *.ppga, *.json)|*.poopliga;*.ppga;*.json|All files (*.*)|*.*",
            FilterIndex = 1,
            RestoreDirectory = true
        };

        var result = saveFileDialog.ShowDialog();
        if (result == DialogResult.OK)
        {
            var path = saveFileDialog.FileName;
            return path;
        }


        return null;
    }
}