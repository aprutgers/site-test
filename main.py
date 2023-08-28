from flask import Flask, redirect, url_for, request
import log
import sitetest
import traceback

application = Flask(__name__)

@application.route('/sitetestweb',methods = ['GET'])
def do_sitetest():
   try:
      action = request.args.get('action')
      domain = request.args.get('domain')
      part   = request.args.get('part')
      ctr    = request.args.get('ctr')
      debug  = request.args.get('debug')
      status = sitetest.webmain(action, domain,part,ctr,debug)
      return status,"200"
   except Exception as err:
      log.logerror(f"main:Exception {err=}, {type(err)=}")
      log.logerror(traceback.format_exc())
      return "ERROR","500"

if __name__ == "__main__":
    log.loginfo('main')
    application.run()
