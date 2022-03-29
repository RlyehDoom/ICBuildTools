<%@ Page Language="C#" Async="true" AutoEventWireup="true" %>
<%@ Import Namespace="System.ComponentModel" %>
<%@ Import Namespace="System.Threading.Tasks" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Web.Services" %>
<%@ Import Namespace="System.Web.Script.Services" %>
<!-- 
    This page need to run with an specific 'APP Pool' running with Admin credentials or the same user who installed NPM/NODE amd GULP-CLI.
 -->
<script language="c#" runat="server">

    Microsoft.Web.Administration.ServerManager serverManager = new Microsoft.Web.Administration.ServerManager();
    System.Diagnostics.ProcessStartInfo processInfo;
    System.Diagnostics.Process process;

    //public static string[] AllowedUsers = { "josey", "tamara.arleo", "andresm", "gabrielap" };
    public static string[] AllowedUsers = { };

    public static class AP
    {
        public static string WorkingDirectory {get;set;}
        public static string BuildName {get;set;}
        public static string Environment { get; set; }
        public static bool ISAsync { get; set; }
    }
    public string outputHTMLResponse;

    public void Page_Load(object sender, EventArgs e)
    {
        Page.Server.ScriptTimeout = 7200;
        outputHTMLResponse = string.Empty;

        string executeDeployment = Request.QueryString["ExecDeplo"];
        string buildName = Request.QueryString["BuildName"];
        string isAsync = Request.QueryString["ISAsync"];

#if DEBUG
            var workingDirectory = ConfigurationManager.AppSettings["WorkingGITDirectoryLocal"].ToString();
#else
        var workingDirectory = ConfigurationManager.AppSettings["WorkingGITDirectoryServer"].ToString();
#endif

        AP.WorkingDirectory = workingDirectory;
        AP.BuildName = buildName;
        if (!string.IsNullOrEmpty(isAsync))
            AP.ISAsync = Convert.ToBoolean(isAsync);
        else
            AP.ISAsync = true;

        if (!Page.IsPostBack)
        {
            string allowedUsersString = ConfigurationManager.AppSettings["AllowedUsersExecutor"].ToString();
            if (!string.IsNullOrEmpty(allowedUsersString) && allowedUsersString != "*")
            {
                string userName = System.Security.Principal.WindowsIdentity.GetCurrent().Name.ToString().Split('\\')[1].ToLower();
                AllowedUsers = allowedUsersString.ToLower().Split(',');
                if (AllowedUsers.Where(p => p.Contains(userName)).Count() > 0)
                {
                    allowedContent.Visible = true;
                    notAllowedContent.Visible = false;
                    CheckIfShouldRunOnLoad(executeDeployment);
                }
                else
                {
                    allowedContent.Visible = false;
                    notAllowedContent.Visible = true;
                }
            }
            else
            {
                allowedContent.Visible = true;
                notAllowedContent.Visible = false;
                CheckIfShouldRunOnLoad(executeDeployment);
            }
        }
    }

    private void CheckIfShouldRunOnLoad(string executeDeployment)
    {
        if (!string.IsNullOrEmpty(executeDeployment) && Convert.ToBoolean(executeDeployment) == true)
        {
            if (AP.ISAsync == false)
            {
                ExeInfo.InnerHtml = RunCMD(AP.WorkingDirectory, "gulp startDeployment --buildName " + AP.BuildName);
            }
            else
            {
                ExeInfo.InnerHtml = "<b>Running Deployment for Build: " + AP.BuildName + " ...please wait.</b><br /><b class='text-danger'>Important:</b> Do Not cancel/close this window!<br />";
            }
        }
    }

    [WebMethod, ScriptMethod(ResponseFormat = ResponseFormat.Json, UseHttpGet = false)]
    public static string GetRunCMDReponse()
    {
        return RunCMD(AP.WorkingDirectory, "gulp startDeployment --buildName " + AP.BuildName);
    }

    public void ExecuteCommand(Object sender, EventArgs e)
    {
        string commandToExecute = CommandToExecuteText.Value;
        var result = RunCMD(AP.WorkingDirectory, commandToExecute);
        ExeInfo.InnerHtml = result;
    }

    public static string RunCMD(string workingDirectory, string commandToRun)
    {
        using (var process = new Process
        {
            StartInfo =
            {
                FileName = "cmd", 
                //Arguments = args,
                UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true, RedirectStandardInput = true,
                WorkingDirectory = workingDirectory, Verb = "runas"
            },
            EnableRaisingEvents = true
        })
        {
            if (string.IsNullOrEmpty(commandToRun))
                commandToRun = "ping 127.0.0.1";

            return RunProcess(process, commandToRun);
        }
    }

    private static string RunProcess(Process process, string commandToRun)
    {
        string responseConsoleOutput = string.Empty;

        bool started = false;
        string output = string.Empty;
        var error = string.Empty;
        try
        {
            started = process.Start();
            if (!started)
            {
                responseConsoleOutput = responseConsoleOutput + string.Format("<br/>Error executing...<br />CommnandToRun: {0}<br />Error Message:{1}<br />", commandToRun, "Process failed to start...") + "<br />";
            }
            process.StandardInput.WriteLine(commandToRun + " & exit");
            output = process.StandardOutput.ReadToEnd();
            error = process.StandardError.ReadToEnd();
            process.WaitForExit(300000 * 3); //15 Minutes....increase if you taks take longer to complete!
            if (process.ExitCode != 0 || error.Contains("ERR!") || error.Contains("Error") || error.Contains("error"))
            {
                responseConsoleOutput = responseConsoleOutput + string.Format("Error executing...<br />CommandToRun:{0}<br />ExitCode:{1} Error Message:{2}<br />", commandToRun, process.ExitCode, error) + "<br />";
            }
            string result = Regex.Replace(output, @"\r\n?|\n", "<br />");
            responseConsoleOutput = responseConsoleOutput + (string.IsNullOrEmpty(result) ? "No Response..." : result);
        }
        catch (Exception ex)
        {
            responseConsoleOutput = responseConsoleOutput + string.Format("<br/>Error executing...<br />CommandToRun: {0}<br />Error Message:{1}<br />", commandToRun, ex.Message) + "<br />";
            return responseConsoleOutput;
        }

        return responseConsoleOutput;
    }

    public void Clean(Object sender, EventArgs e)
    {
        ExeInfo.InnerHtml = "";
        var uri = new Uri(Page.Request.Url.ToString());
        string path = uri.GetLeftPart(UriPartial.Path);
        Page.Response.Redirect(path, true);
    }
</script>

<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content=".NET's Executor" />
    <meta name="author" content="José Luis Yañez Rojas" />
    <meta name="generator" content="RlyehDoom 0.0.1" />

    <title>.NET's Executor</title>
    <link href="bootstrap/assets/dist/css/bootstrap.min.css" rel="stylesheet" />

    <script type="text/javascript">
        function CheckThis(sender, args) {
            console.log('Button [' + sender.id + '] clicked!');
            if (document.getElementById("CommandToExecuteText").value != '') {
                document.getElementById("ExeInfo").innerHTML = '<h2 class="text-danger">Running your command.</h2><br/><h4>Please patiently wait for a response here...</h4>';
                return true;
            }
            else {
                alert('Command to execute invalid!');
                return false;
            }
        }
    </script>
    <script type="text/javascript">
        function DisableButton() {
            document.getElementById("ExecuteCommandButton").disabled = true;
        }
        window.onbeforeunload = DisableButton;
    </script>
    <style>
        body {
            background-image: linear-gradient(180deg, #eee, #fff 100px, #fff);
        }

        .container {
            max-width: 1280px;
        }

        .bd-placeholder-img {
            font-size: 1.125rem;
            text-anchor: middle;
            -webkit-user-select: none;
            -moz-user-select: none;
            user-select: none;
        }

        @media (min-width: 768px) {
            .bd-placeholder-img-lg {
                font-size: 3.5rem;
            }
        }
    </style>
    <script src="jquery/jquery-3.6.0.min.js"></script>
    <script type="text/javascript">
        function getParameterByName(name, url) {
            if (!url) url = window.location.href;
            name = name.replace(/[\[\]]/g, "\\$&");
            var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
                results = regex.exec(url);
            if (!results) return null;
            if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, " "));
        }
        //If the page was executed with the parameters ExecDeplo & BuildName then we run the command and we hide the Daemons.
        $(document).ready(function () {
            var execDeplo = getParameterByName('ExecDeplo');
            var buildName = getParameterByName('BuildName');
            var isAsync = getParameterByName('ISAsync');
            isAsync = isAsync == null ? 'true' : isAsync;
            if (execDeplo != null && buildName != null && isAsync.toLowerCase() == 'true') {
                console.log('About to execute [GetRunCMDAsyncReponse]');
                document.getElementById("ExecuteCommandButton").disabled = true;
                $.ajax({
                    type: "POST",
                    url: "NETExecutor.aspx/GetRunCMDReponse",
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        $('#ExeInfo').html(response.d);
                        document.getElementById("ExecuteCommandButton").disabled = false;
                    },
                    failure: function (response) {
                        alert(response.d);
                    }
                });
            }
        });
    </script>
</head>
<body>
    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="check" viewBox="0 0 16 16">
            <title>Check</title>
            <path d="M13.854 3.646a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L6.5 10.293l6.646-6.647a.5.5 0 0 1 .708 0z" />
        </symbol>
    </svg>
    <div class="container py-3">
        <form id="formMain" runat="server">
            <header>
                <div class="d-flex flex-column flex-md-row align-items-center pb-3 mb-4 border-bottom">
                    <a href="/" class="d-flex align-items-center text-dark text-decoration-none">
                        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="32" class="me-2" viewBox="0 0 118 94" role="img">
                            <title>Bootstrap</title>
                            <path fill-rule="evenodd" clip-rule="evenodd" d="M24.509 0c-6.733 0-11.715 5.893-11.492 12.284.214 6.14-.064 14.092-2.066 20.577C8.943 39.365 5.547 43.485 0 44.014v5.972c5.547.529 8.943 4.649 10.951 11.153 2.002 6.485 2.28 14.437 2.066 20.577C12.794 88.106 17.776 94 24.51 94H93.5c6.733 0 11.714-5.893 11.491-12.284-.214-6.14.064-14.092 2.066-20.577 2.009-6.504 5.396-10.624 10.943-11.153v-5.972c-5.547-.529-8.934-4.649-10.943-11.153-2.002-6.484-2.28-14.437-2.066-20.577C105.214 5.894 100.233 0 93.5 0H24.508zM80 57.863C80 66.663 73.436 72 62.543 72H44a2 2 0 01-2-2V24a2 2 0 012-2h18.437c9.083 0 15.044 4.92 15.044 12.474 0 5.302-4.01 10.049-9.119 10.88v.277C75.317 46.394 80 51.21 80 57.863zM60.521 28.34H49.948v14.934h8.905c6.884 0 10.68-2.772 10.68-7.727 0-4.643-3.264-7.207-9.012-7.207zM49.948 49.2v16.458H60.91c7.167 0 10.964-2.876 10.964-8.281 0-5.406-3.903-8.178-11.425-8.178H49.948z" fill="currentColor"></path></svg>
                        <span class="fs-4">.NET's Executor</span>
                    </a>

                    <nav class="d-inline-flex mt-2 mt-md-0 ms-md-auto">
                        <asp:LinkButton ID="CleanButton" ClientIDMode="Static" CssClass="me-3 py-2 text-dark text-decoration-none" runat="server" OnClick="Clean">Reset</asp:LinkButton>
                    </nav>
                </div>
                <div class="pricing-header p-3 pb-md-4 mx-auto text-center">
                    <h1 class="display-4 fw-normal">.NET's Executor</h1>
                    <p class="fs-5 text-muted">Use this web page to execute a specific executable from your environment.</p>
                    <p class="fs-5 text-muted"><i>Explanation:</i> This process will open a CMD window in your server and execute any given command</p>
                </div>
            </header>
            <main>
                <div id="allowedContent" runat="server" class="row">
                    <div class="row mb-3">
                        <div class="col-auto">
                            <label for="CommandToExecuteText" class="col-sm-2 col-form-label text-nowrap">CMD Command:</label>
                        </div>
                        <div class="col-sm-8">
                            <input type="text" id="CommandToExecuteText" runat="server" class="form-control" value="" placeholder="example: gulp startDeployment --buildName RBEC_QA" />
                        </div>
                        <div class="col-sm-2">
                            <asp:Button ID="ExecuteCommandButton" runat="server" ClientIDMode="Static" Text="Run" CssClass="btn btn-primary" OnClientClick="return CheckThis(this);" OnClick="ExecuteCommand" />
                        </div>
                    </div>
                    <br />
                    <h3>Executable Results: 
                  <p id="ExeInfo" class="lead" runat="server"></p>
                    </h3>
                </div>
                <div id="notAllowedContent" runat="server" class="row">
                    <div class="col">
                        <h3>Warning: 
                            <p class="lead text-danger">You don't have permissions to operate this page...</p>
                            <p>Allowd Users: <b><%= ConfigurationManager.AppSettings["AllowedUsersExecutor"].ToString() %></b></p>
                        </h3>
                    </div>
                </div>
            </main>
        </form>
    </div>

    <script src="bootstrap/assets/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
        var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl)
        });
    </script>
</body>
</html>
