import fs from "fs";
import { execSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DemFolder = path.join(__dirname, "Downloads");
//Get All Arguments From Command Line

const argumnts = process.argv;

class MM {
  /**
   * @Todo check The Process for the Whole CSV DATA
   *
   */
  _Link;
  _DemoLinks;
  _Payload;
  constructor(link) {
    this._DemoLinks = null;
    this._Link = link;
    this._Payload = {
      _DemoLinksAvaliable: 0,
      _FileDownloadAndExtracted: 0,
      _FileFailedToDownload: 0,
      _LinksDownloadFail: [],
      _DemosSuccefullyProccessed: 0,
      _DemoosFailedProcessing: 0,
      _PathsToDemosThatFailedProcessing: [],
    };
  }
  _VerifyLink() {
    /**
     *  @disc  checks weather the argument is a File PATH or a Demo Link
     *  @returns boolean True if its a Demo Link False if its a Path
     *  @arguments type string path or a Demo link
     */

    if (this._Link.startsWith("https://")) {
      this._DemoLinks = [{ SteamID: Date.now().toString(), Link: this._Link }];
      return true;
    } else {
      return false;
    }
  }
  _VerifyPath() {
    /**
     * @disc checks the existance of the CSV file
     * @returns boolean
     */
    let exists = fs.existsSync(this._Link);
    if (exists) {
      return true;
    } else {
      return false;
    }
  }
  async _DownloadFiles() {
    /**
     * @disc Loop Thru All The Links in the CSV and Download All of them using rclone
     * @return number of files Downloaded and Extracted and Number of files Failed to download
     * @argument _DemoLinks
     */
    this._DemoLinks.map(async (item) => {
      const { SteamID, Link } = item;
      console.log("Starting The Download Process for :", Link);
      try {
        const ExecDownload = await execSync(
          `rclone copyurl ${Link} ./dist/Downloads/${SteamID}/${SteamID}.dem.gz`
        );
        console.log("Starting Extraction");
        //Extraction and Deleting the Old file
        const ExtractFile = await execSync(
          `gunzip ./dist/Downloads/${SteamID}/${SteamID}.dem.gz`
        );
        this._Payload._FileDownloadAndExtracted++;
      } catch (error) {
        this._Payload._FileFailedToDownload++;
        this._Payload._LinksDownloadFail?.push({ SteamID, Link });
        console.log(error.status);
      }
    });
  }
  async _ProcessFile() {
    /**
     * @disc Starts a Process Sync For each Folder That is in the Download File
     * @argument _DistinationPath
     * @retuns Files_Processed : number  Files_Failed_Process : number Files_Paths_That_Failed = []
     */
    let FilesNames = fs.readdirSync(DemFolder);
    FilesNames.map(async (FileName) => {
      try {
        console.log("[+] Python Script starting with Folder :" + FileName);
        let Execution = await execSync(
          `python3 ./processor/test.py ${FileName}/`
        );
        console.log(Execution.toString())
        this._Payload._DemosSuccefullyProccessed++;
      } catch (error) {
        this._Payload._DemoosFailedProcessing++;
        this._Payload._PathsToDemosThatFailedProcessing.push(FileName);
        console.log("[-] Process Terminated with Code :" + error.status);
      }
    });
  }
  async _ReadFile() {
    /**
     * @disc Reads a CSV file
     * @arguments Path To The file
     * @retuns Object with SteamID and Link
     */
    const CsvData = await fs.readFileSync(this._Link);
    let Text = CsvData.toString();
    let newText = Array.from(Text.split("\n"));
    let FinalForm = newText.map((item) => {
      let T = item.split(",");
      return {
        SteamID: T[0],
        Link: T[1],
      };
    });
    this._DemoLinks = FinalForm;
  }
  async _exec() {
    if (this._VerifyLink()) {
      await this._DownloadFiles();
      await this._ProcessFile();
      return this._Payload;
    } else {
      if (this._VerifyPath()) {
        console.log("[-] File Exist");
        await this._ReadFile();
        await this._DownloadFiles();
        await this._ProcessFile();
        return this._Payload;
      } else {
        console.log("[-] File Does Not Exist");
        process.exit(1);
      }
    }
  }
}
console.log(await new MM(argumnts[2])._exec());
//console.log(await new MM(Link)._exec());
