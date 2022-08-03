### Refactoring Notes
- Build solid set of tests for the code before doing refactoring
- Create background jobs for sending SMS
- In DebtsController, extract create contact to a separate class -> CreateContact
- In DebtsController, extract generating SMS body to a separate class -> GenerateSMSBody
- In ClientSMS, Introduce Gateway. Also can be able to switch to different SMS service providers